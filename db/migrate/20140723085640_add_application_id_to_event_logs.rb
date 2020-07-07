class AddApplicationIdToEventLogs < ActiveRecord::Migration[3.2]
  def change
    add_column :event_logs, :application_id, :integer
  end
end
