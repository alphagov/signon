class AddEventIdToEventLogs < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :event_logs, :event_id, :integer
  end
end
