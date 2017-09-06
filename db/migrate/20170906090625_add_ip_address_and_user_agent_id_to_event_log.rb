class AddIpAddressAndUserAgentIdToEventLog < ActiveRecord::Migration
  def change
    add_column :event_logs, :ip_address, :integer, limit: 8
    add_column :event_logs, :user_agent_id, :integer

    add_foreign_key :event_logs, :user_agents
  end
end
