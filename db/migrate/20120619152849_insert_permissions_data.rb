class InsertPermissionsData < ActiveRecord::Migration
  def up
    everything_app = ::Doorkeeper::Application.create!(name: "Everything", uid: "not-a-real-app", secret: "does-not-have-a-secret", redirect_uri: "https://not-a-domain.com")
    User.all.each do |user|
      Permission.create(application: everything_app, user: user, permissions: %w[signin])
    end
  end

  def down
    ::Doorkeeper::Application.find_by_name("Everything").delete
    Permission.delete_all
  end
end
