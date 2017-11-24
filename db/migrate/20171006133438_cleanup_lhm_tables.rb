class CleanupLhmTables < ActiveRecord::Migration[4.2]
  def up
    Lhm.cleanup(:run)
  end

  def down
    # This migration cannot be reversed
  end
end
