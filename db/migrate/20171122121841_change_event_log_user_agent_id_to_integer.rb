class ChangeEventLogUserAgentIdToInteger < ActiveRecord::Migration[5.1]
  def up
    change_column :event_logs, :user_agent_id, "BIGINT"
  end

  def down
    change_column :event_logs, :user_agent_id, "INT"
  end
end
