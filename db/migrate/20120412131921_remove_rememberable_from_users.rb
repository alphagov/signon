class RemoveRememberableFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :remember_created_at
  end
end
