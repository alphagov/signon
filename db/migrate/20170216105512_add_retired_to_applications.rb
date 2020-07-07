class AddRetiredToApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :retired, :boolean, default: false
  end
end
