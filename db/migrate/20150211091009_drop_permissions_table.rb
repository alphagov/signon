class DropPermissionsTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :permissions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
