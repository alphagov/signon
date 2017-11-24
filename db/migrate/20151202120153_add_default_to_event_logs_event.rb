class AddDefaultToEventLogsEvent < ActiveRecord::Migration[4.2]
  def up
    change_column_default :event_logs, :event, ""
  end
end
