class AddDeletedAtToApplication < ActiveRecord::Migration
  def up
    add_column :oauth_applications, :deleted_at, :time
    add_index :oauth_applications, :deleted_at
  end

  def down
    remove_column :oauth_applications, :deleted_at
    remove_index :oauth_applications, :deleted_at
  end
end
