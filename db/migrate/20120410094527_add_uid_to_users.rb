class AddUidToUsers < ActiveRecord::Migration[3.2]
  def change
    add_column :users, :uid, :string
  end
end
