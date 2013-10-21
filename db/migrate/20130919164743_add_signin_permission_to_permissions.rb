class AddSigninPermissionToPermissions < ActiveRecord::Migration
  def change
    add_column :permissions, :signin_permission, :boolean, default: false
  end
end
