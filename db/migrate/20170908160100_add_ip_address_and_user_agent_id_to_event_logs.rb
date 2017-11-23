require 'lhm'

class AddIpAddressAndUserAgentIdToEventLogs < ActiveRecord::Migration
  def self.up
    Lhm.cleanup(:run)
    Lhm.change_table :event_logs do |m|
      m.add_column :ip_address, "BIGINT"
      m.add_column :user_agent_id, "BIGINT"
      m.ddl("ALTER TABLE %s ADD CONSTRAINT event_logs_user_agent_id_fk FOREIGN KEY (user_agent_id) REFERENCES user_agents(id)" % m.name)
    end
  end

  def self.down
    remove_foreign_key :event_logs, name: :event_logs_user_agent_id_fk
    Lhm.cleanup(:run)
    Lhm.change_table :event_logs do |m|
      m.remove_column :user_agent_id
      m.remove_column :ip_address
    end
  end
end
