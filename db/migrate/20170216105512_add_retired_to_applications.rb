class AddRetiredToApplications < ActiveRecord::Migration[4.2]
  def change
    add_column :oauth_applications, :retired, :boolean, default: false
  end
end
