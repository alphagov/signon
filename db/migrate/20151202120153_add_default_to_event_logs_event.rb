class AddDefaultToEventLogsEvent < ActiveRecord::Migration[6.0]
  def up
    change_column_default :event_logs, :event, ""
  end
end
