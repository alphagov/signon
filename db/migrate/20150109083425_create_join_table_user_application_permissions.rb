class CreateJoinTableUserApplicationPermissions < ActiveRecord::Migration
  def change
    create_table :user_application_permissions do |t|
      t.integer :user_id, null: false
      t.integer :application_id, null: false
      t.integer :supported_permission_id, null: false
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :user_application_permissions, :user_id
    add_index :user_application_permissions, [:user_id, :application_id]
  end
end
