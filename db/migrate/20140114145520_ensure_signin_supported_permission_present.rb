class EnsureSigninSupportedPermissionPresent < ActiveRecord::Migration
  def up
    require "enhancements/application.rb"

    Doorkeeper::Application.all.each do |application|
      next if application.signin_permission.present?

      application.supported_permissions.create!(name: "signin", delegatable: true)
    end
  end
end
