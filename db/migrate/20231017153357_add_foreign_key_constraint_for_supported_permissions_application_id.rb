class AddForeignKeyConstraintForSupportedPermissionsApplicationId < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :supported_permissions, :oauth_applications, column: :application_id
  end
end
