class AddPasswordChangedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_changed_at, :datetime
    User.update_all "password_changed_at = confirmed_at"
  end
end
