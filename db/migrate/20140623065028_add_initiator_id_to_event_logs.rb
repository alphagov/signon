class AddInitiatorIdToEventLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :event_logs, :initiator_id, :integer
  end
end
