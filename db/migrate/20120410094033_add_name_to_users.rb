class AddNameToUsers < ActiveRecord::Migration[3.2]
  def change
    add_column :users, :name, :string
  end
end
