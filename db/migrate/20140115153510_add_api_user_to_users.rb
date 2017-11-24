class AddApiUserToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :api_user, :boolean, default: false, null: false
  end
end
