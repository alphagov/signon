class AddApplicationIdToEventLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :event_logs, :application_id, :integer
  end
end
