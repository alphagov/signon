class AddApiUserToUsers < ActiveRecord::Migration[3.2]
  def change
    add_column :users, :api_user, :boolean, default: false, null: false
  end
end
