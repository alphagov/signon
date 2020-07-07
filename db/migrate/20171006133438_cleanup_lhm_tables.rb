class CleanupLhmTables < ActiveRecord::Migration[6.0]
  def up
    Lhm.cleanup(:run)
  end

  def down
    # This migration cannot be reversed
  end
end
