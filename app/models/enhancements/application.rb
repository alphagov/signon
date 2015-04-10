require "doorkeeper/orm/active_record/application"

class ::Doorkeeper::Application < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_many :permissions, :dependent => :destroy
  has_many :supported_permissions, :dependent => :destroy

  # TODO: Remove this accessible attributes list once Signonotron has upgraded
  # to Rails 4. Doorkeeper itself uses `attr_accessible` only if we're using
  # Rails < 4 (see https://github.com/doorkeeper-gem/doorkeeper/blob/master/lib/doorkeeper/models/application_mixin.rb#L18-L20)
  # Unfortunately, in doing that, we're prevented from updating any attributes
  # Doorkeeper hasn't explicitly whitelisted, and so need to continue using
  # attr_accessible here ourselves.
  attr_accessible(
    :name,
    :description,
    :uid,
    :secret,
    :redirect_uri,
    :home_uri,
    :supports_push_updates,
  )

  default_scope order('oauth_applications.name')
  scope :support_push_updates, where(supports_push_updates: true)
  scope :can_signin, lambda {|user| joins(:supported_permissions => :user_application_permissions)
                                    .where('user_application_permissions.user_id' => user.id)
                                    .where('supported_permissions.name' => 'signin') }
  scope :with_signin_delegatable, joins(:supported_permissions)
                                  .where(supported_permissions: { name: 'signin', delegatable: true })

  after_create :create_signin_supported_permission
  after_save :create_user_update_supported_permission

  def self.policy_class; ApplicationPolicy; end

  def supported_permission_strings(user=nil)
    if user && user.role == 'organisation_admin'
      supported_permissions.delegatable.pluck(:name) & user.permissions_for(self)
    else
      supported_permissions.pluck(:name)
    end
  end

  def signin_permission
    supported_permissions.where(name: 'signin').first
  end

  def sorted_supported_permissions_grantable_from_ui
    ([signin_permission] + (supported_permissions.grantable_from_ui.order(:name) - [signin_permission])).compact
  end

  def url_without_path
    parsed_url = URI.parse(redirect_uri)
    url_without_path = "#{parsed_url.scheme}://#{parsed_url.host}:#{parsed_url.port}"
  end

private

  def create_signin_supported_permission
    supported_permissions.create!(name: 'signin', delegatable: true)
  end

  def create_user_update_supported_permission
    supported_permissions.where(name: 'user_update_permission', grantable_from_ui: false).first_or_create! if supports_push_updates?
  end
end
