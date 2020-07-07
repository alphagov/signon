class AddInitiatorIdToEventLogs < ActiveRecord::Migration[3.2]
  def change
    add_column :event_logs, :initiator_id, :integer
  end
end
