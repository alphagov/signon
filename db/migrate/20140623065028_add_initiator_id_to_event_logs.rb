class AddInitiatorIdToEventLogs < ActiveRecord::Migration
  def change
    add_column :event_logs, :initiator_id, :integer
  end
end
