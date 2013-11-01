class UserInSingleOrganisation < ActiveRecord::Migration
  def up
    drop_table :organisations_users

    add_column :users, :organisation_id, :integer
    add_index :users, :organisation_id
  end

  def down
    remove_column :users, :organisation_id

    create_table :organisations_users do |t|
      t.integer :organisation_id
      t.integer :user_id
    end
    add_index :organisations_users, :organisation_id
    add_index :organisations_users, :user_id
  end
end
