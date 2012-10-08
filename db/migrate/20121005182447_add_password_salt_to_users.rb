class AddPasswordSaltToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_salt, :string
    change_column :users, :encrypted_password, :string, limit: 255
  end
end
