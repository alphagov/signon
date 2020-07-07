class RemoveRememberableFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :remember_created_at
  end
end
