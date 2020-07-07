class RemoveEventColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :event_logs, :event
  end
end
