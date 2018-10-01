class CreateJoinTableUserApplicationPermissions < ActiveRecord::Migration
  def change
    create_table :user_application_permissions do |t|
      t.integer :user_id, null: false
      t.integer :application_id, null: false
      t.integer :supported_permission_id, null: false
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :user_application_permissions, %i[user_id application_id supported_permission_id],
                unique: true,
                name: "index_app_permissions_on_user_and_app_and_supported_permission"
  end
end
