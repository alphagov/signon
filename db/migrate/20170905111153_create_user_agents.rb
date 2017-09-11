class CreateUserAgents < ActiveRecord::Migration
  def change
    create_table :user_agents do |t|
      t.string :user_agent_string,    index: true, null: false, :limit => 1000
    end
  end
end
