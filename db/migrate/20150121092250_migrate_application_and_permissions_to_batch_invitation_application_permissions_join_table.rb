class MigrateApplicationAndPermissionsToBatchInvitationApplicationPermissionsJoinTable < ActiveRecord::Migration
  def up
    puts "Updating #{BatchInvitation.count} batch invitations"

    BatchInvitation.all.each do |batch_invitation|
      _supported_permissions = []
      batch_invitation.applications_and_permissions.values.each do |permission_attributes|
        application_id = permission_attributes["application_id"]
        permissions = permission_attributes["permissions"]
        _supported_permissions << SupportedPermission.where(application_id: application_id, name: permissions) if permissions.present?
      end
      batch_invitation.update_attributes(supported_permissions: _supported_permissions.flatten)
    end
    puts "Done."
  end
end
