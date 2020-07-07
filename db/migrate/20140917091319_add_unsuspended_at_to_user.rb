class AddUnsuspendedAtToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :unsuspended_at, :datetime
  end
end
