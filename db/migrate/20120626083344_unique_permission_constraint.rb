class UniquePermissionConstraint < ActiveRecord::Migration
  def up
    add_index :permissions, [:application_id, :user_id], unique: true, name: "unique_permission_constraint"
  end

  def down
    remove_index :permissions, "unique_permission_constraint"
  end
end
