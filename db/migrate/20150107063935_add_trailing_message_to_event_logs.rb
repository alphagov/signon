class AddTrailingMessageToEventLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :event_logs, :trailing_message, :string
  end
end
