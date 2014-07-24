class AddApplicationIdToEventLogs < ActiveRecord::Migration
  def change
    add_column :event_logs, :application_id, :integer
  end
end
