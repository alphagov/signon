class AddUnsuspendedAtToUser < ActiveRecord::Migration[3.2]
  def change
    add_column :users, :unsuspended_at, :datetime
  end
end
