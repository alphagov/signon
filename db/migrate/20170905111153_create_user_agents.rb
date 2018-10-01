class CreateUserAgents < ActiveRecord::Migration
  def change
    create_table :user_agents do |t|
      t.string :user_agent_string, null: false, limit: 1000
    end

    add_index :user_agents, :user_agent_string, length: { user_agent_string: 255 }
  end
end
