class FixUserUpdatePermission < ActiveRecord::Migration
  def up
    SupportedPermission.where(name: 'user_update_permission')
                       .update_all(grantable_from_ui: false)
  end
end
