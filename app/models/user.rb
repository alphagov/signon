# coding: utf-8

class User < ActiveRecord::Base
  include Roles # adds validations and accessible attributes

  self.include_root_in_json = true

  SUSPENSION_THRESHOLD_PERIOD = 45.days
  UNSUSPENSION_GRACE_PERIOD = 3.days

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
  has_many :permissions, inverse_of: :user
  has_many :batch_invitations
  belongs_to :organisation

  before_validation :fix_apostrophe_in_email
  before_create :generate_uid
  after_create :update_stats

  accepts_nested_attributes_for :permissions, :allow_destroy => true

  scope :web_users, where(api_user: false)
  scope :not_suspended, where(suspended_at: nil)
  scope :with_role, lambda { |role_name| where(role: role_name) }
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

  def authorised_applications
    authorisations.group_by(&:application).map(&:first)
  end
  alias_method :applications_used, :authorised_applications

  def grant_permission(application, permission)
    grant_permissions(application, [permission])
  end

  def grant_permissions(application, permissions)
    permission_record = self.permissions.find_by_application_id(application.id) || self.permissions.build(application_id: application.id)
    new_permissions = Set.new(permission_record.permissions || [])
    new_permissions += permissions

    permission_record.permissions = new_permissions.to_a
    permission_record.save!
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
  end

  def status
    return "suspended" if suspended?
    unless api_user?
      return "invited" if invited_but_not_yet_accepted?
      return "passphrase expired" if need_change_password?
    end
    return "locked" if access_locked?

    "active"
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
