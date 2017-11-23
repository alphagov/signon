class AddTrailingMessageToEventLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :event_logs, :trailing_message, :string
  end
end
