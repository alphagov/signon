class AddApiUserToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_user, :boolean, default: false, null: false
  end
end
