class AddDefaultFlagToSupportedPermissions < ActiveRecord::Migration[4.2]
  def change
    add_column :supported_permissions, :default, :boolean, default: false, null: false
  end
end
