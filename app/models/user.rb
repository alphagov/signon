class User < ApplicationRecord
  include Roles

  self.include_root_in_json = true

  NEVER_SIGNED_IN_EXPIRY_PERIOD = 90.days

  SUSPENSION_THRESHOLD_PERIOD = 45.days
  UNSUSPENSION_GRACE_PERIOD = 7.days

  MAX_2SV_LOGIN_ATTEMPTS = 10
  REMEMBER_2SV_SESSION_FOR = 30.days

  USER_STATUS_SUSPENDED = "suspended".freeze
  USER_STATUS_INVITED = "invited".freeze
  USER_STATUS_LOCKED = "locked".freeze
  USER_STATUS_ACTIVE = "active".freeze
  USER_STATUSES = [USER_STATUS_ACTIVE,
                   USER_STATUS_SUSPENDED,
                   USER_STATUS_INVITED,
                   USER_STATUS_LOCKED].freeze

  TWO_STEP_STATUS_ENABLED = "enabled".freeze
  TWO_STEP_STATUS_NOT_SET_UP = "not_set_up".freeze
  TWO_STEP_STATUS_EXEMPTED = "exempted".freeze

  TWO_STEP_STATUSES_VS_NAMED_SCOPES = {
    TWO_STEP_STATUS_ENABLED => "has_2sv",
    TWO_STEP_STATUS_NOT_SET_UP => "not_setup_2sv",
    TWO_STEP_STATUS_EXEMPTED => "exempt_from_2sv",
  }.freeze

  devise :database_authenticatable,
         :recoverable,
         :trackable,
         :validatable,
         :timeoutable,
         :lockable, # devise core model extensions
         :invitable,    # in devise_invitable gem
         :suspendable,  # in signon/lib/devise/models/suspendable.rb
         :zxcvbnable,
         :encryptable,
         :confirmable,
         :password_archivable # in signon/lib/devise/models/password_archivable.rb

  delegate :manageable_roles, to: :role
  delegate :display_name, to: :role, prefix: true
  delegate :name, to: :role, prefix: true, allow_nil: true

  encrypts :otp_secret_key

  validates :name, presence: true
  validates :email, reject_non_governmental_email_addresses: true
  validates :reason_for_suspension, presence: true, if: proc { |u| u.suspended? }
  validates :role, inclusion: { in: Roles.all }
  validate :user_can_be_exempted_from_2sv
  validate :organisation_admin_belongs_to_organisation
  validate :email_is_ascii_only
  validate :exemption_from_2sv_data_is_complete
  validate :organisation_has_mandatory_2sv, on: :create

  has_many :authorisations, -> { joins(:application) }, class_name: "Doorkeeper::AccessToken", foreign_key: :resource_owner_id
  has_many :authorised_applications, -> { distinct(:application) }, through: :authorisations, source: :application
  has_many :application_permissions, -> { joins(:application) }, class_name: "UserApplicationPermission", inverse_of: :user, dependent: :destroy
  has_many :supported_permissions, -> { joins(:application) }, through: :application_permissions
  has_many :batch_invitations
  belongs_to :organisation

  before_validation :fix_apostrophe_in_email
  after_initialize :generate_uid
  before_save :set_2sv_for_admin_roles
  before_save :reset_2sv_exemption_reason
  before_save :mark_two_step_mandated_changed
  before_save :update_password_changed
  before_save :strip_whitespace_from_name

  scope :web_users, -> { where(api_user: false) }

  scope :suspended, -> { where.not(suspended_at: nil) }
  scope :not_suspended, -> { where(suspended_at: nil) }
  scope :invited, -> { where.not(invitation_sent_at: nil).where(invitation_accepted_at: nil) }
  scope :not_invited, -> { where(invitation_sent_at: nil).or(where.not(invitation_accepted_at: nil)) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :not_locked, -> { where(locked_at: nil) }
  scope :active, -> { not_suspended.not_invited.not_locked }

  scope :exempt_from_2sv, -> { where.not(reason_for_2sv_exemption: nil) }
  scope :not_exempt_from_2sv, -> { where(reason_for_2sv_exemption: nil) }
  scope :has_2sv, -> { where.not(otp_secret_key: nil) }
  scope :does_not_have_2sv, -> { where(otp_secret_key: nil) }
  scope :not_setup_2sv, -> { not_exempt_from_2sv.does_not_have_2sv }

  scope :with_role, ->(role) { where(role:) }
  scope :with_permission, ->(permission) { joins(:supported_permissions).merge(SupportedPermission.unscoped.where(id: permission)).distinct }
  scope :with_organisation, ->(organisation) { where(organisation:) }
  scope :with_partially_matching_name, ->(name) { where(arel_table[:name].matches("%#{name}%")) }
  scope :with_partially_matching_email, ->(email) { where(arel_table[:email].matches("%#{email}%")) }
  scope :with_partially_matching_name_or_email, ->(value) { with_partially_matching_name(value).or(with_partially_matching_email(value)) }

  scope :last_signed_in_on, ->(date) { web_users.not_suspended.where("date(current_sign_in_at) = date(?)", date) }
  scope :last_signed_in_before, ->(date) { web_users.not_suspended.where("date(current_sign_in_at) < date(?)", date) }
  scope :last_signed_in_after, ->(date) { web_users.not_suspended.where("date(current_sign_in_at) >= date(?)", date) }
  scope :never_signed_in, -> { web_users.where(current_sign_in_at: nil) }
  scope :expired_never_signed_in, -> { never_signed_in.where("invitation_sent_at < ?", NEVER_SIGNED_IN_EXPIRY_PERIOD.ago) }
  scope :not_recently_unsuspended, -> { where(["unsuspended_at IS NULL OR unsuspended_at < ?", UNSUSPENSION_GRACE_PERIOD.ago]) }
  scope :with_access_to_application, ->(application) { UsersWithAccess.new(self, application).users }

  def self.with_statuses(statuses)
    permitted_statuses = statuses.intersection(USER_STATUSES)
    relations = permitted_statuses.map { |s| public_send(s) }
    relation = relations.pop || all
    while (next_relation = relations.pop)
      relation = relation.or(next_relation)
    end
    relation
  end

  def self.with_2sv_statuses(scope_names)
    permitted_scopes = scope_names.intersection(TWO_STEP_STATUSES_VS_NAMED_SCOPES.values)
    relations = permitted_scopes.map { |s| public_send(s) }
    relation = relations.pop || all
    while (next_relation = relations.pop)
      relation = relation.or(next_relation)
    end
    relation
  end

  def self.with_default_permissions
    new(supported_permissions: SupportedPermission.default)
  end

  def role
    Roles.find(self[:role])
  end

  def require_2sv?
    return require_2sv unless organisation

    (organisation.require_2sv? && !exempt_from_2sv?) || require_2sv
  end

  def prompt_for_2sv?
    return false if has_2sv?

    require_2sv?
  end

  def exempt_from_2sv?
    reason_for_2sv_exemption.present?
  end

  def event_logs(event: nil)
    relation = EventLog.where(uid:)
    relation = relation.merge(EventLog.where(event_id: event.id)) if event.present?

    relation.order(created_at: :desc).includes(:user_agent)
  end

  def generate_uid
    self.uid ||= UUID.generate
  end

  def analytics_user_id
    "XXX#{uid}XXX"
  end

  def permissions_for(application)
    application_permissions
      .joins(:supported_permission)
      .where(application_id: application.id)
      .order(SupportedPermission.arel_table[:name])
      .pluck(SupportedPermission.arel_table[:name])
  end

  # Avoid N+1 queries by using the relations eager loaded with `includes()`.
  def eager_loaded_permission_for(application)
    application_permissions.select { |p| p.application_id == application.id }.map(&:supported_permission).map(&:name)
  end

  def permission_ids_for(application)
    application_permissions.select { |ap| ap.application_id == application.id }.map(&:supported_permission_id)
  end

  def has_access_to?(application)
    application_permissions.detect { |permission| permission.supported_permission_id == application.signin_permission.id }
  end

  def has_permission?(supported_permission)
    if persisted?
      supported_permissions.exists?(supported_permission.id)
    else
      supported_permissions.any? { |sp| sp.id == supported_permission.id }
    end
  end

  def permissions_synced!(application)
    application_permissions.where(application_id: application.id).update_all(last_synced_at: Time.current)
  end

  def revoke_all_authorisations
    authorisations.not_revoked.find_each(&:revoke)
  end

  def grant_application_signin_permission(application)
    grant_application_permission(application, SupportedPermission::SIGNIN_NAME)
  end

  def grant_application_permission(application, supported_permission_name)
    grant_application_permissions(application, [supported_permission_name]).first
  end

  def grant_application_permissions(application, supported_permission_names)
    return [] if application.retired?

    supported_permission_names.map do |supported_permission_name|
      supported_permission = SupportedPermission.find_by(application_id: application.id, name: supported_permission_name)
      grant_permission(supported_permission)
    end
  end

  def grant_permission(supported_permission)
    if persisted?
      application_permissions.where(supported_permission_id: supported_permission.id).first_or_create!
    else
      supported_permissions << supported_permission unless supported_permissions.include?(supported_permission)
    end
  end

  # This overrides `Devise::Recoverable` behavior.
  def self.send_reset_password_instructions(attributes = {})
    user = User.find_by(email: attributes[:email])
    if user.present? && user.suspended?
      UserMailer.notify_reset_password_disallowed_due_to_suspension(user).deliver_later
      user
    elsif user.present? && user.invited_but_not_yet_accepted?
      UserMailer.notify_reset_password_disallowed_due_to_unaccepted_invitation(user).deliver_later
      user
    else
      super
    end
  end

  def unusable_account?
    invited_but_not_yet_accepted? || suspended? || access_locked?
  end

  # Required for devise_invitable to set role and permissions
  def self.inviter_role(inviter)
    inviter.nil? ? :default : inviter.role_name.to_sym
  end

  def invite!(*args)
    # For us, a user is "confirmed" when they're created, even though this is
    # conceptually confusing.
    # It means that the password reset flow works when you've been invited but
    # not yet accepted.
    # Devise Invitable used to behave this way and then changed in v1.1.1
    self.confirmed_at = Time.current
    super(*args)
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

  def cancel_email_change!
    self.unconfirmed_email = nil
    self.confirmation_token = nil
    save!(validate: false)
  end

  def invited_but_not_yet_accepted?
    invitation_sent_at.present? && invitation_accepted_at.nil?
  end

  # Override Devise::Model::Lockable#lock_access! to add event logging
  def lock_access!(opts = {})
    event = locked_reason == :two_step ? EventLog::TWO_STEP_LOCKED : EventLog::ACCOUNT_LOCKED
    EventLog.record_event(self, event)

    super
  end

  def status
    return USER_STATUS_SUSPENDED if suspended?

    if web_user? && invited_but_not_yet_accepted?
      return USER_STATUS_INVITED
    end

    return USER_STATUS_LOCKED if access_locked?

    USER_STATUS_ACTIVE
  end

  def two_step_status
    if has_2sv?
      TWO_STEP_STATUS_ENABLED
    elsif exempt_from_2sv?
      TWO_STEP_STATUS_EXEMPTED
    else
      TWO_STEP_STATUS_NOT_SET_UP
    end
  end

  def not_setup_2sv?
    two_step_status == TWO_STEP_STATUS_NOT_SET_UP
  end

  def can_manage?(other_user)
    role.can_manage?(other_user.role)
  end

  def manageable_organisations
    role.manageable_organisations_for(self)
  end

  # Make devise send all emails using ActiveJob
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def need_two_step_verification?
    has_2sv?
  end

  def set_2sv_for_admin_roles
    return unless GovukEnvironment.production?

    self.require_2sv = true if role_changed? && role.require_2sv?
  end

  def reset_2sv_exemption_reason
    if require_2sv.present?
      self.reason_for_2sv_exemption = nil
      self.expiry_date_for_2sv_exemption = nil
    end
  end

  def authenticate_otp(code)
    result = CodeVerifier.new(code, otp_secret_key).verify

    if result
      update!(second_factor_attempts_count: 0)
      EventLog.record_event(self, EventLog::TWO_STEP_VERIFIED)
    else
      increment!(:second_factor_attempts_count)
      EventLog.record_event(self, EventLog::TWO_STEP_VERIFICATION_FAILED)
      lock_access! if max_2sv_login_attempts?
    end

    result
  end

  def locked_reason
    if max_2sv_login_attempts?
      :two_step
    else
      :password
    end
  end

  def max_2sv_login_attempts?
    second_factor_attempts_count.to_i >= MAX_2SV_LOGIN_ATTEMPTS.to_i
  end

  def unlock_access!(*args)
    super
    update!(second_factor_attempts_count: 0)
  end

  def has_2sv?
    otp_secret_key.present?
  end

  def exempt_from_2sv(reason, initiating_user, expiry_date)
    initial_reason = reason_for_2sv_exemption
    update!(require_2sv: false, reason_for_2sv_exemption: reason, otp_secret_key: nil, expiry_date_for_2sv_exemption: expiry_date)

    if initial_reason.blank?
      EventLog.record_event(self, EventLog::TWO_STEP_EXEMPTED, initiator: initiating_user, trailing_message: "for reason: #{reason} expiring on date: #{expiry_date}")
    else
      EventLog.record_event(self, EventLog::TWO_STEP_EXEMPTION_UPDATED, initiator: initiating_user, trailing_message: "to: #{reason} expiring on date: #{expiry_date}")
    end
  end

  def reset_2sv!(initiator)
    transaction do
      self.otp_secret_key = nil
      self.require_2sv = true
      save!

      EventLog.record_event(
        self,
        EventLog::TWO_STEP_RESET,
        initiator:,
      )
    end
  end

  def send_two_step_mandated_notification?
    require_2sv? && two_step_mandated_changed?
  end

  def belongs_to_gds?
    organisation.try(:content_id).to_s == Organisation::GDS_ORG_CONTENT_ID
  end

  def organisation_name
    organisation.present? ? organisation.name : Organisation::NONE
  end

  def web_user?
    !api_user?
  end

private

  def two_step_mandated_changed?
    @two_step_mandated_changed
  end

  def mark_two_step_mandated_changed
    @two_step_mandated_changed = require_2sv_changed?
    true
  end

  def user_can_be_exempted_from_2sv
    errors.add(:reason_for_2sv_exemption, "cannot be blank for #{role_display_name} users. Remove the user's exemption to change their role.") if exempt_from_2sv? && role.require_2sv?
  end

  def organisation_admin_belongs_to_organisation
    if publishing_manager? && organisation_id.blank?
      errors.add(:organisation_id, "can't be 'None' for #{role_display_name}")
    end
  end

  def email_is_ascii_only
    errors.add(:email, "can't contain non-ASCII characters") unless email.blank? || email.ascii_only?
  end

  def exemption_from_2sv_data_is_complete
    errors.add(:expiry_date_for_2sv_exemption, "must be present if exemption reason is present") if reason_for_2sv_exemption.present? && expiry_date_for_2sv_exemption.nil?
    errors.add(:reason_for_2sv_exemption, "must be present if exemption expiry date is present") if expiry_date_for_2sv_exemption.present? && reason_for_2sv_exemption.blank?
  end

  def organisation_has_mandatory_2sv
    errors.add(:require_2sv, "2-step verification is mandatory for all users from this organisation") if organisation && organisation.require_2sv? && !require_2sv
  end

  def fix_apostrophe_in_email
    email.tr!("’", "'") if email.present? && email_changed?
  end

  def strip_whitespace_from_name
    name.strip!
  end

  def update_password_changed
    self.password_changed_at = Time.current if (new_record? || encrypted_password_changed?) && !password_changed_at_changed?
  end
end
