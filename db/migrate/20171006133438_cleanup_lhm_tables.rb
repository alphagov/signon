class CleanupLhmTables < ActiveRecord::Migration
  def up
    Lhm.cleanup(:run)
  end

  def down
    # This migration cannot be reversed
  end
end
