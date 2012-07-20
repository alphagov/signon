class AddLastSyncedAtToPermission < ActiveRecord::Migration
  def change
    add_column :permissions, :last_synced_at, :datetime
  end
end
