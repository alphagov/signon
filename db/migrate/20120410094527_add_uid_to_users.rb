class AddUidToUsers < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :users, :uid, :string
  end
end
