class AddGrantableFromUiToSupportedPermissions < ActiveRecord::Migration
  def change
    add_column :supported_permissions, :grantable_from_ui, :boolean, null: false, default: true
  end
end
