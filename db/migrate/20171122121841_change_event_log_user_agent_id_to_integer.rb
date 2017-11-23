class ChangeEventLogUserAgentIdToInteger < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :event_logs, :user_agents
    change_column :user_agents, :id, "BIGINT"
    change_column :event_logs, :user_agent_id, "BIGINT"
    add_foreign_key :event_logs, :user_agents
  end

  def down
    remove_foreign_key :event_logs, :user_agents
    change_column :user_agents, :id, "INT"
    change_column :event_logs, :user_agent_id, "INT"
    add_foreign_key :event_logs, :user_agents
  end
end
