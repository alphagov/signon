class AddDelegatableToSupportedPermissions < ActiveRecord::Migration[3.2]
  def change
    add_column :supported_permissions, :delegatable, :boolean, default: false
  end
end
