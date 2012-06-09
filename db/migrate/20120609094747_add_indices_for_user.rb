class AddIndicesForUser < ActiveRecord::Migration
  def up
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end

  def down
    remove_index :users, :email, unique: true
    remove_index :users, :reset_password_token
  end
end
