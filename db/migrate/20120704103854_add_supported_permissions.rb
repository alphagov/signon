class AddSupportedPermissions < ActiveRecord::Migration[3.2]
  def change
    create_table :supported_permissions do |t|
      t.references :application
      t.string :name

      t.timestamps
    end
    add_index :supported_permissions, :application_id
  end
end
