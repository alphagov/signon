class AddDefaultToEventLogsEvent < ActiveRecord::Migration
  def up
    change_column_default :event_logs, :event, ""
  end
end
