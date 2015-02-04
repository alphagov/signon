require 'enhancements/application'

class AddUserUpdateSupportedPermissionToApplications < ActiveRecord::Migration
  def change
    Doorkeeper::Application.where(supports_push_updates: true).each do |application|
      application.supported_permissions.where(name: 'user_update_permission').first_or_create!
    end
  end
end
