class AddDescriptionToApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :home_uri, :string
    add_column :oauth_applications, :description, :string

    Doorkeeper::Application.reset_column_information
    Doorkeeper::Application.find_each do |app|
      p = URI.parse(app.redirect_uri)
      app.update_column(:home_uri, "https://#{p.host}")
    end
  end
end
