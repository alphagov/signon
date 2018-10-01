class AddBulkGrantPermissionSets < ActiveRecord::Migration
  def change
    create_table :bulk_grant_permission_sets do |t|
      t.belongs_to :user, null: false
      t.string :outcome
      t.integer :processed_users, default: 0, null: false
      t.integer :total_users, default: 0, null: false
      t.timestamps
    end

    create_table :bulk_grant_permission_set_application_permissions do |t|
      t.belongs_to :bulk_grant_permission_set, null: false
      t.belongs_to :supported_permission, null: false
      t.timestamps
    end

    add_index :bulk_grant_permission_set_application_permissions, %i[bulk_grant_permission_set_id supported_permission_id],
                unique: true,
                name: "index_app_permissions_on_bulk_grant_permission_set"
  end
end
