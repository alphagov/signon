class ChangeEventLogsTrailingMessageColumn < ActiveRecord::Migration[7.0]
  def up
    change_column :event_logs, :trailing_message, :text
  end

  def down
    change_column :event_logs, :trailing_message, :string
  end
end
