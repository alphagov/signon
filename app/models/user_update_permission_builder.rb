class UserUpdatePermissionBuilder
  def initialize(user:, updatable_permission_ids:, selected_permission_ids:)
    @user = user
    @updatable_permission_ids = updatable_permission_ids
    @selected_permission_ids = selected_permission_ids
  end

  def build
    permissions_user_has = @user.supported_permissions.pluck(:id)
    permissions_to_add = @updatable_permission_ids.intersection(@selected_permission_ids)
    permissions_to_remove = @updatable_permission_ids.difference(@selected_permission_ids)

    (permissions_user_has + permissions_to_add - permissions_to_remove).sort
  end
end
