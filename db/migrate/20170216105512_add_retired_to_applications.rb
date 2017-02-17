class AddRetiredToApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :retired, :boolean, default: false
  end
end
