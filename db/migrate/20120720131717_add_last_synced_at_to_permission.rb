class AddLastSyncedAtToPermission < ActiveRecord::Migration[4.2]
  def up
    add_column :permissions, :last_synced_at, :datetime
    execute("update permissions set last_synced_at = updated_at")
  end
end
