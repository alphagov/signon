class IndexEventLogsColumns < ActiveRecord::Migration[7.1]
  def change
    change_table :event_logs, bulk: true do
      add_index :event_logs, :application_id
      add_index :event_logs, :event_id
    end
  end
end
