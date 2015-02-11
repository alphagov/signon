class DropPermissionsTable < ActiveRecord::Migration
  def up
    drop_table :permissions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
