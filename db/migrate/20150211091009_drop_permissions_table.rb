class DropPermissionsTable < ActiveRecord::Migration[4.2]
  def up
    drop_table :permissions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
