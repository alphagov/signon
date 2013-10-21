require 'password_migration'
require 'paginate_alphabetically'

class User < ActiveRecord::Base
  paginate_alphabetically :by => :name

  self.include_root_in_json = true

  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable,                # devise core model extensions
         :invitable,    # in devise_invitable gem
         :suspendable,  # in signonotron2/lib/devise/models/suspendable.rb
         :strengthened, # in signonotron2/lib/devise/models/strengthened.rb
         :encryptable,
         :confirmable,
         :password_expirable

  attr_accessible :uid, :name, :email, :password, :password_confirmation
  attr_accessible :uid, :name, :email, :password, :password_confirmation, :permissions_attributes, as: :admin
  attr_accessible :uid, :name, :email, :password, :password_confirmation, :permissions_attributes, :role, as: :superadmin
  attr_readonly :uid

  validates :name, presence: true
  validates :reason_for_suspension, presence: true, if: proc { |u| u.suspended? }
  def self.roles
    {
      "Normal user" => "normal",
      "Admin" => "admin",
      "Superadmin" => "superadmin"
    }
  end
  validates :role, inclusion: { in: roles.values }

  has_many :authorisations, :class_name => 'Doorkeeper::AccessToken', :foreign_key => :resource_owner_id
  has_many :permissions
  has_many :batch_invitations
  has_and_belongs_to_many :organisations

  before_create :generate_uid

  after_create :update_stats

  accepts_nested_attributes_for :permissions, :allow_destroy => true

  def generate_uid
    self.uid = UUID.generate
  end

  def to_sensible_json(for_application)
    permission = self.permissions.where(application_id: for_application.id).first
    { user: { uid: uid, name: name, email: email, permissions: permission.nil? ? [] : permission.permissions } }.to_json
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
    unsupported_permissions = permissions - application.supported_permission_strings
    if unsupported_permissions.any?
      raise UnsupportedPermissionError, "Cannot grant '#{unsupported_permissions.join("', '")}' permission(s), they are not supported by the '#{application.name}' application"
    end

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

  def has_role?(possible)
    if role == "superadmin"
      true
    else
      role == possible
    end
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

  include PasswordMigration
end
