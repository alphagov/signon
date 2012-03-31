class RemoveRememberableFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :remember_created_at
  end
end
