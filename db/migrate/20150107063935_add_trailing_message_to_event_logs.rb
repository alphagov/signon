class AddTrailingMessageToEventLogs < ActiveRecord::Migration
  def change
    add_column :event_logs, :trailing_message, :string
  end
end
