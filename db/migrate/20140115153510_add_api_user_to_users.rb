class AddApiUserToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :api_user, :boolean, default: false, null: false
  end
end
