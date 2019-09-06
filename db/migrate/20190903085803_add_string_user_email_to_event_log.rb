class AddStringUserEmailToEventLog < ActiveRecord::Migration[5.2]
  def change
    add_column :event_logs, :user_email_string, :string
  end
end
