class CreatePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :permissions do |t|
      t.references :user
      t.references :application
      t.text :permissions

      t.timestamps
    end
    add_index :permissions, :user_id
    add_index :permissions, :application_id
  end
end
