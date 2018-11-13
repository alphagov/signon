class AddConfidentialToApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :confidential, :boolean, default: true, null: false
  end
end
