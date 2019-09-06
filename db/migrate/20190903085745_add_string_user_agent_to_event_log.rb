class AddStringUserAgentToEventLog < ActiveRecord::Migration[5.2]
  def change
    add_column :event_logs, :user_agent_string, :string
  end
end
