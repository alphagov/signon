class UniqueApplicationConstraint < ActiveRecord::Migration
  def up
    add_index :oauth_applications, "name", unique: true, name: "unique_application_name"
  end

  def down
    remove_index :oauth_applications, "unique_application_name"
  end
end
