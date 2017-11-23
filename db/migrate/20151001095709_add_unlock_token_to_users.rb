class AddUnlockTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :unlock_token, :string, length: 64
    add_index :users, :unlock_token, unique: true
  end
end
