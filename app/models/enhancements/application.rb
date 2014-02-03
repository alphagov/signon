require "doorkeeper/models/application"

class ::Doorkeeper::Application < ActiveRecord::Base
  has_many :permissions, :dependent => :destroy
  has_many :supported_permissions, :dependent => :destroy

  attr_accessible :name, :description, :uid, :secret, :redirect_uri, :home_uri
  attr_accessible :supports_push_updates, role: :superadmin

  default_scope order(:name)
  scope :support_push_updates, where(supports_push_updates: true)
  scope :can_signin, lambda { |user| joins(:permissions)
                                      .where(permissions: { user_id: user.id })
                                      .where('permissions.permissions LIKE ?', '%signin%') }
  scope :with_signin_delegatable, joins(:supported_permissions)
                                  .where(supported_permissions: { name: 'signin', delegatable: true })

  after_create :create_signin_supported_permission

  def supported_permission_strings(user=nil)
    if user && user.role == 'organisation_admin'
      supported_permissions.delegatable.map(&:name) &
        user.permissions.find_by_application_id(id).permissions
    else
      supported_permissions.map(&:name)
    end
  end

  def signin_permission
    supported_permissions.where(name: 'signin').first
  end

  def sorted_supported_permissions
    ([signin_permission] + (supported_permissions.order(:name) - [signin_permission])).compact
  end

  def url_without_path
    parsed_url = URI.parse(redirect_uri)
    url_without_path = "#{parsed_url.scheme}://#{parsed_url.host}:#{parsed_url.port}"
  end

private

  def create_signin_supported_permission
    supported_permissions.create!(name: 'signin', delegatable: true)
  end
end
