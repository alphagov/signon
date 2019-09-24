require "enhancements/application"

class AddUserUpdateSupportedPermissionToApplications < ActiveRecord::Migration
  def change
    Doorkeeper::Application.where(supports_push_updates: true).each do |application|
      application.supported_permissions.create!(name: "user_update_permission", grantable_from_ui: false)
    end
  end
end
