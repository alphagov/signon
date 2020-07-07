class AddEventIdToEventLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :event_logs, :event_id, :integer
  end
end
