class AddPasswordChangedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_changed_at, :datetime
    User.update_all ['password_changed_at = ?', '2013-03-06 20:00:00']
  end
end
