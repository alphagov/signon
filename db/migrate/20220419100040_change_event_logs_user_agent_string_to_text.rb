class ChangeEventLogsUserAgentStringToText < ActiveRecord::Migration[7.0]
  def up
    change_column :event_logs, :user_agent_string, :text
  end

  def down
    change_column :event_logs, :user_agent_string, :string
  end
end
