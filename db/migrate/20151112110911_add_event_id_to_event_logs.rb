class AddEventIdToEventLogs < ActiveRecord::Migration
  def change
    add_column :event_logs, :event_id, :integer
  end
end
