class CleanupOldTable < ActiveRecord::Migration
  def up
    drop_table "_event_logs_old"
  end

  def down
    # This migration cannot be reversed
  end
end
