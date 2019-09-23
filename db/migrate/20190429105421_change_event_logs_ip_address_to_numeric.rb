require "lhm"

class ChangeEventLogsIpAddressToNumeric < ActiveRecord::Migration[5.2]
  def self.up
    remove_foreign_key :event_logs, name: :event_logs_user_agent_id_fk
    Lhm.cleanup(:run)
    Lhm.change_table :event_logs do |m|
      m.change_column :ip_address, "DECIMAL(38,0)"
      m.ddl("ALTER TABLE %s ADD CONSTRAINT event_logs_user_agent_id_fk FOREIGN KEY (user_agent_id) REFERENCES user_agents(id)" % m.name)
    end
  end

  def self.down
    remove_foreign_key :event_logs, name: :event_logs_user_agent_id_fk
    Lhm.cleanup(:run)
    Lhm.change_table :event_logs do |m|
      m.change_column :ip_address, "BIGINT"
      m.ddl("ALTER TABLE %s ADD CONSTRAINT event_logs_user_agent_id_fk FOREIGN KEY (user_agent_id) REFERENCES user_agents(id)" % m.name)
    end
  end
end
