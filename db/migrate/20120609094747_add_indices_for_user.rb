class AddIndicesForUser < ActiveRecord::Migration
  def try_to
    begin
      yield
    rescue StandardError => e
      puts e
    end
  end

  def up
    try_to { add_index :users, :email, unique: true }
    try_to { add_index :users, :reset_password_token, unique: true }
  end

  def down
    remove_index :users, :email, unique: true
    remove_index :users, :reset_password_token
  end
end
