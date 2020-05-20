class UserPermissionMigrator
  def self.migrate(source:, target:)
    source_app = Doorkeeper::Application.find_by!(name: source)
    target_app = Doorkeeper::Application.find_by!(name: target)
    source_app_supported_permissions = source_app.supported_permissions
    target_app_supported_permissions = target_app.supported_permissions

    permissions = source_app_supported_permissions.map do |permission|
      [permission.name, target_app_supported_permissions.find_by!(name: permission.name)]
    end

    permission_mappings = permissions.to_h

    User.all.each do |user|
      next unless user.has_access_to?(source_app)

      permissions = user.permissions_for(source_app)
      permissions.each do |permission|
        UserApplicationPermission.create user: user, application: target_app, supported_permission: permission_mappings[permission]
      end
    end
  end
end
