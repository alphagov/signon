class EnsureSigninSupportedPermissionPresent < ActiveRecord::Migration[3.2]
  def up
    require "doorkeeper/application.rb"

    Doorkeeper::Application.all.each do |application|
      next if application.signin_permission.present?

      application.supported_permissions.create!(name: "signin", delegatable: true)
    end
  end
end
