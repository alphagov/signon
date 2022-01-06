class RemoveOldDiagnosticTable < ActiveRecord::Migration[6.1]
  def up
    drop_table :lhma_2019_04_29_13_15_20_064_event_logs, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
