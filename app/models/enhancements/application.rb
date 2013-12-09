require "doorkeeper/models/application"

class ::Doorkeeper::Application < ActiveRecord::Base
  has_many :permissions, :dependent => :destroy
  has_many :supported_permissions, :dependent => :destroy

  attr_accessible :name, :description, :uid, :secret, :redirect_uri, :home_uri

  def self.default_permission_strings
    # Excludes user_update_permission which is granted automatically when needed
    # to the special SSO Push User
    ["signin"]
  end

  def supported_permission_strings
    self.class.default_permission_strings + supported_permissions.order(:name).map(&:name)
  end

  def signin_permission
    supported_permissions.where(name: ['signin', 'Signin']).first
  end

  def sorted_supported_permissions
    ([signin_permission] + (supported_permissions.order(:name) - [signin_permission])).compact
  end

  def url_without_path
    parsed_url = URI.parse(redirect_uri)
    url_without_path = "#{parsed_url.scheme}://#{parsed_url.host}:#{parsed_url.port}"
  end
end
