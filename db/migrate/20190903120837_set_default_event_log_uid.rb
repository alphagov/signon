class SetDefaultEventLogUid < ActiveRecord::Migration[5.2]
  def change
    change_column_null :event_logs, :uid, true
    change_column_default :event_logs, :uid, nil
  end
end
