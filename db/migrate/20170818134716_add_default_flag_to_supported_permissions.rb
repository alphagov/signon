class AddDefaultFlagToSupportedPermissions < ActiveRecord::Migration
  def change
    add_column :supported_permissions, :default, :boolean, default: false, null: false
  end
end
