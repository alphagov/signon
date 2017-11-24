class AddPasswordChangedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :password_changed_at, :datetime
    User.update_all "password_changed_at = GREATEST('2013-03-06 20:00:00', confirmed_at)"
  end
end
