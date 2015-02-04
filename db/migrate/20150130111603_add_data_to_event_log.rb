class AddDataToEventLog < ActiveRecord::Migration
  def change
    add_column :event_logs, :data, :text
  end
end
