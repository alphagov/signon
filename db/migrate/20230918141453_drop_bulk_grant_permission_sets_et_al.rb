class DropBulkGrantPermissionSetsEtAl < ActiveRecord::Migration[7.0]
  def change
    drop_table :bulk_grant_permission_set_application_permissions do |t|
      t.belongs_to :bulk_grant_permission_set,
                   null: false,
                   index: { name: "index_bulk_grant_permissions_on_bulk_grant_permission_set_id" }
      t.belongs_to :supported_permission,
                   null: false,
                   index: { name: "index_bulk_grant_permissions_on_permission_id" }

      t.timestamps

      t.index %i[bulk_grant_permission_set_id supported_permission_id],
              name: "index_bulk_grant_permissions_on_permission_id_and_bulk_grant_id",
              unique: true
    end

    drop_table :bulk_grant_permission_sets do |t|
      t.belongs_to :user
      t.string :outcome
      t.integer :processed_users, default: 0, null: false
      t.integer :total_users, default: 0, null: false

      t.timestamps
    end
  end
end
