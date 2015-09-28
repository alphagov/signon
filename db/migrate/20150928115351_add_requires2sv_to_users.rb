class AddRequires2svToUsers < ActiveRecord::Migration
  def change
    add_column :users, :requires_2sv, :boolean, null: false, default: false
  end
end
