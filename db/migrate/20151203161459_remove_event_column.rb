class RemoveEventColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column :event_logs, :event
  end
end
