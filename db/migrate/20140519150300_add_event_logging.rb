class AddEventLogging < ActiveRecord::Migration
  def self.up
    create_table :event_logs do |t|
      t.string   :uid, null: false
      t.string   :event, null: false
      t.datetime :created_at
    end

    add_index :event_logs, :uid
  end

  def self.down
    drop_table :event_logs
  end
end
