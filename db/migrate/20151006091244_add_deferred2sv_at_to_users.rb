class AddDeferred2svAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :deferred_2sv_at, :datetime, null: true
  end
end
