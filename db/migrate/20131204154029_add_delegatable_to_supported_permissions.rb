class AddDelegatableToSupportedPermissions < ActiveRecord::Migration[6.0]
  def change
    add_column :supported_permissions, :delegatable, :boolean, default: false
  end
end
