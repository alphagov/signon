class AddGrantableFromUiToSupportedPermissions < ActiveRecord::Migration[4.2]
  def change
    add_column :supported_permissions, :grantable_from_ui, :boolean, null: false, default: true
  end
end
