class FixUserUpdatePermission < ActiveRecord::Migration
  def up
    SupportedPermission.update_all({ grantable_from_ui: false }, { name: 'user_update_permission' })
  end
end
