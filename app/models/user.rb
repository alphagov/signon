# coding: utf-8

class User < ActiveRecord::Base
  include Roles # adds validations and accessible attributes

  self.include_root_in_json = true

  SUSPENSION_THRESHOLD_PERIOD = 45.days
  UNSUSPENSION_GRACE_PERIOD = 3.days

  USER_STATUS_SUSPENDED = 'suspended'
  USER_STATUS_INVITED = 'invited'
  USER_STATUS_PASSPHRASE_EXPIRED = 'passphrase expired'
  USER_STATUS_LOCKED = 'locked'
  USER_STATUS_ACTIVE = 'active'
  USER_STATUSES = [USER_STATUS_SUSPENDED, USER_STATUS_INVITED, USER_STATUS_PASSPHRASE_EXPIRED,
                   USER_STATUS_LOCKED, USER_STATUS_ACTIVE]

  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable,                # devise core model extensions
         :invitable,    # in devise_invitable gem
         :suspendable,  # in signonotron2/lib/devise/models/suspendable.rb
         :async,        # in devise_async gem, send mailers async'ly
         :zxcvbnable,
         :encryptable,
         :confirmable,
         :password_expirable,
         :password_archivable

  attr_readonly :uid

  validates :name, presence: true
  validates :reason_for_suspension, presence: true, if: proc { |u| u.suspended? }
  validate :organisation_admin_belongs_to_organisation
  validate :email_is_ascii_only

  has_many :authorisations, :class_name => 'Doorkeeper::AccessToken', :foreign_key => :resource_owner_id
  has_many :application_permissions, class_name: 'UserApplicationPermission', inverse_of: :user
  has_many :supported_permissions, through: :application_permissions
  has_many :batch_invitations
  has_many :event_logs, primary_key: :uid, foreign_key: :uid, order: 'created_at DESC'
  belongs_to :organisation

  before_validation :fix_apostrophe_in_email
  before_create :generate_uid
  after_create :update_stats

  scope :web_users, where(api_user: false)
  scope :not_suspended, where(suspended_at: nil)
  scope :with_role, lambda { |role_name| where(role: role_name) }
  scope :with_organisation, lambda { |org_id| where(organisation_id: org_id) }
  scope :filter, lambda { |filter_param| where("users.email like ? OR users.name like ?", "%#{filter_param.strip}%", "%#{filter_param.strip}%") }
  scope :last_signed_in_on, lambda { |date| web_users.not_suspended.where('date(current_sign_in_at) = date(?)', date) }
  scope :last_signed_in_before, lambda { |date| web_users.not_suspended.where('date(current_sign_in_at) < date(?)', date) }
  scope :last_signed_in_after, lambda { |date| web_users.not_suspended.where('date(current_sign_in_at) >= date(?)', date) }
  scope :not_recently_unsuspended, lambda { where(['unsuspended_at IS NULL OR unsuspended_at < ?', UNSUSPENSION_GRACE_PERIOD.ago]) }

  def generate_uid
    self.uid = UUID.generate
  end

  def invited_but_not_accepted
    !invitation_sent_at.nil? && invitation_accepted_at.nil?
  end

  def permissions_for(application)
    application_permissions.joins(:supported_permission).where(application_id: application.id).pluck(:name)
  end

  def permission_ids_for(application)
    application_permissions.where(application_id: application.id).pluck(:supported_permission_id)
  end

  def has_access_to?(application)
    application_permissions.detect {|permission| permission.supported_permission_id == application.signin_permission.id }
  end

  def permissions_synced!(application)
    application_permissions.where(application_id: application.id).update_all(last_synced_at: Time.zone.now)
  end

  def authorised_applications
    authorisations.group_by(&:application).map(&:first)
  end
  alias_method :applications_used, :authorised_applications

  def grant_application_permission(application, supported_permission_name)
    grant_application_permissions(application, [supported_permission_name]).first
  end

  def grant_application_permissions(application, supported_permission_names)
    supported_permission_names.map do |supported_permission_name|
      supported_permission = SupportedPermission.find_by_application_id_and_name(application.id, supported_permission_name)
      application_permissions.where(application_id: application.id, supported_permission_id: supported_permission.id).first_or_create!
    end
  end

  # override Devise::Recoverable behavior to:
  # 1. notify suspended users that they can't reset their password, and
  # 2. handle emails blacklisted by AWS such that we conceal whether
  #    or not an account exists for that email. moved from:
  #    https://github.com/alphagov/signonotron2/commit/451b89d9
  def self.send_reset_password_instructions(attributes={})
    user = User.find_by_email(attributes[:email])
    if user.present? && user.suspended?
      UserMailer.delay.notify_reset_password_disallowed_due_to_suspension(user)
      user
    else
      super
    end
  rescue Net::SMTPFatalError => exception
    exception.message =~ /Address blacklisted/i ? user : raise
  end

  # Required for devise_invitable to set role and permissions
  def self.inviter_role(inviter)
    inviter.nil? ? :default : inviter.role.to_sym
  end

  def invite!
    # For us, a user is "confirmed" when they're created, even though this is
    # conceptually confusing.
    # It means that the password reset flow works when you've been invited but
    # not yet accepted.
    # Devise Invitable used to behave this way and then changed in v1.1.1
    self.confirmed_at = Time.zone.now
    super
  end

  # Override Devise so that, when a user has been invited with one address
  # and then it is changed, we can send a new invitation email, rather than
  # a confirmation email (and hence they'll be in the correct flow re setting
  # their first password)
  def postpone_email_change?
    if invited_but_not_yet_accepted?
      false
    else
      super
    end
  end

  def invited_but_not_yet_accepted?
    invitation_sent_at.present? && invitation_accepted_at.nil?
  end

  def update_stats
    Statsd.new(::STATSD_HOST).increment("#{::STATSD_PREFIX}.users.created")
  end

  # Override Devise::Model::Lockable#lock_access! to add event logging
  def lock_access!
    EventLog.record_event(User.find_by_email(self.email),EventLog::ACCOUNT_LOCKED)
    super

    UserMailer.delay.locked_account_explanation(self)
  end

  def status
    return USER_STATUS_SUSPENDED if suspended?
    unless api_user?
      return USER_STATUS_INVITED if invited_but_not_yet_accepted?
      return USER_STATUS_PASSPHRASE_EXPIRED if need_change_password?
    end
    return USER_STATUS_LOCKED if access_locked?

    USER_STATUS_ACTIVE
  end

  def manageable_roles
    "Roles::#{role.camelize}".constantize.manageable_roles
  end

private

  # Override devise_security_extension for updating expired passwords
  def update_password_changed
    super.tap do |result|
      EventLog.record_event(self, EventLog::SUCCESSFUL_PASSPHRASE_CHANGE) if result
    end
  end

  def organisation_admin_belongs_to_organisation
    if self.role == 'organisation_admin' && self.organisation_id.blank?
      errors.add(:organisation_id, "can't be 'None' for an Organisation admin")
    end
  end

  def email_is_ascii_only
    errors.add(:email, "can't contain non-ASCII characters") unless email.blank? or email.ascii_only?
  end

  def fix_apostrophe_in_email
    self.email.tr!(%q(’), %q(')) if email.present? and email_changed?
  end

end
