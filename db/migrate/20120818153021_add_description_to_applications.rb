class AddDescriptionToApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :home_uri, :string
    add_column :oauth_applications, :description, :string

    Doorkeeper::Application.find_each do |app|
      p = URI.parse(app.redirect_uri)
      app.update_attribute :home_url, "https://#{p.host}"
    end
  end
end
