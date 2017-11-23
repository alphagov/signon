class AddUniqueIndexToSupportedPermissions < ActiveRecord::Migration[4.2]
  def change
    add_index :supported_permissions, [:application_id, :name], unique: true
  end
end
