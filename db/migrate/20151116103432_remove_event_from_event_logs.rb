class RemoveEventFromEventLogs < ActiveRecord::Migration
  def change
    remove_column :event_logs, :event
  end
end
