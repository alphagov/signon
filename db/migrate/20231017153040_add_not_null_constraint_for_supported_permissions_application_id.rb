class AddNotNullConstraintForSupportedPermissionsApplicationId < ActiveRecord::Migration[7.0]
  def change
    change_column_null :supported_permissions, :application_id, false
  end
end
