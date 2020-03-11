class Permission < ApplicationRecord
  belongs_to :user
  belongs_to :application, class_name: "Doorkeeper::Application"
  serialize :permissions, Array
end

class MigratePermissionsToUserApplicationPermissionsJoinTable < ActiveRecord::Migration
  class Permission < ApplicationRecord
  end

  def up
    puts "Migrating #{Permission.count} permissions to user_application_permissions join table"
    cache_supported_permissions

    index = 0
    Permission.find_each do |permission|
      permission.permissions.each do |supported_permission_name|
        _supported_permission = @cache[permission.application_id][supported_permission_name]
        next unless _supported_permission

        permission = UserApplicationPermission.new(user_id: permission.user_id,
                                                   application_id: permission.application_id,
                                                   supported_permission_id: _supported_permission.id,
                                                   last_synced_at: permission.last_synced_at,
                                                   created_at: permission.created_at,
                                                   updated_at: permission.updated_at)
        permission.save if permission.valid? # doesn't save duplicate permissions
      end
      print "." if (index += 1) % 1000 == 0
    end
    puts ""
    puts "Done."
  end

  # caching saves us about 30s
  def cache_supported_permissions
    @cache ||= {}
    SupportedPermission.all.each do |supported_permission|
      @cache[supported_permission.application_id] ||= {}
      @cache[supported_permission.application_id][supported_permission.name] = supported_permission
    end
  end
end
