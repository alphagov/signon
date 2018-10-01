class AddUniqueIndexToSupportedPermissions < ActiveRecord::Migration
  def change
    add_index :supported_permissions, %i[application_id name], unique: true
  end
end
