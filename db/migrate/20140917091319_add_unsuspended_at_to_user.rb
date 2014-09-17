class AddUnsuspendedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :unsuspended_at, :datetime
  end
end
