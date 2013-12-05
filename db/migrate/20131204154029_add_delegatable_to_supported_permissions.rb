class AddDelegatableToSupportedPermissions < ActiveRecord::Migration
  def change
    add_column :supported_permissions, :delegatable, :boolean, default: false
  end
end
