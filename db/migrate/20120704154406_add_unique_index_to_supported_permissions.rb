class AddUniqueIndexToSupportedPermissions < ActiveRecord::Migration[6.0]
  def change
    add_index :supported_permissions, %i[application_id name], unique: true
  end
end
