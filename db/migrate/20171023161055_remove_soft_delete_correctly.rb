class RemoveSoftDeleteCorrectly < ActiveRecord::Migration
  def up
    remove_index :oauth_applications, :deleted_at if index_exists?(:oauth_applications, :deleted_at)
    remove_column :oauth_applications, :deleted_at if column_exists?(:oauth_applications, :deleted_at)
  end

  def down
    add_column :oauth_applications, :deleted_at, :time
    add_index :oauth_applications, :deleted_at
  end
end
