class AddForeignKeyConstraintForUserApplicationPermissionsApplicationId < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :user_application_permissions, :oauth_applications, column: :application_id
  end
end
