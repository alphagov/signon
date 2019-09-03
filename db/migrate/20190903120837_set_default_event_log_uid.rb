class SetDefaultEventLogUid < ActiveRecord::Migration[5.2]
  def change
    change_column :event_logs, :uid, null: true
    change_column_default :event_logs, :uid, nil
  end
end
