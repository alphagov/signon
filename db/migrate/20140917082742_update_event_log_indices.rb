class UpdateEventLogIndices < ActiveRecord::Migration[3.2]
  def up
    change_column :event_logs, :created_at, :datetime, null: false
    add_index :event_logs, %i[uid created_at]
    remove_index :event_logs, :uid
  end

  def down
    change_column :event_logs, :created_at, :datetime, null: true
    add_index :event_logs, :uid
    remove_index :event_logs, %i[uid created_at]
  end
end
