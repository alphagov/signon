class CleanupOldTable < ActiveRecord::Migration[4.2][4.2]
  def up
    drop_table "_event_logs_old"
  end

  def down
    # This migration cannot be reversed
  end
end
