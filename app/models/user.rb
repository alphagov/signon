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
         :confirmable

  attr_accessible :uid, :name, :email, :password, :password_confirmation
  attr_accessible :uid, :name, :email, :password, :password_confirmation, :is_admin, :permissions_attributes, as: :admin
  attr_readonly :uid

  validates :name, presence: true
  validates :reason_for_suspension, presence: true, if: proc { |u| u.suspended? }

  has_many :authorisations, :class_name => 'Doorkeeper::AccessToken', :foreign_key => :resource_owner_id
  has_many :permissions

  before_create :generate_uid

  after_create :update_stats

  accepts_nested_attributes_for :permissions, :allow_destroy => true

  def generate_uid
    self.uid = UUID.generate
  end

  def to_sensible_json(for_application)
    sensible_permissions = {}
    permissions = self.permissions.where(application_id: for_application.id)
    permissions.each do |permission|
      sensible_permissions[permission.application.name] = permission.permissions
    end
    { user: { uid: uid, name: name, email: email, permissions: sensible_permissions } }.to_json
  end

  def invited_but_not_accepted
    !invitation_sent_at.nil? && invitation_accepted_at.nil?
  end

  def authorised_applications
    authorisations.group_by(&:application).map(&:first)
  end
  alias_method :applications_used, :authorised_applications

  # Required for devise_invitable to set is_admin and permissions
  def self.inviter_role(inviter)
    :admin
  end

  def accept_invitation!
    # We want to "confirm" an account when a user accepts an invitation,
    # otherwise confirmable won't let them log in.
    # Unfortunately, this is also (for some reason) called when a password 
    # is reset via email so, as a workaround, don't attempt confirmation 
    # if already confirmed
    self.confirmed_at = Time.now.utc unless confirmed_at.present?
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
