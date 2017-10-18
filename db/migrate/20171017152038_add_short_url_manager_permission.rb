class AddShortUrlManagerPermission < ActiveRecord::Migration
  def up
    app = Doorkeeper::Application.find_by(name: "Short URL Manager")
    manage_short_urls = SupportedPermission.find_by(application: app, name: "manage_short_urls")
    receive_notifications = SupportedPermission.create!(application: app, name: "receive_notifications")
    manage_short_urls.user_application_permissions.each do |uap|
      UserApplicationPermission.create!(user: uap.user, supported_permission: receive_notifications)
    end
  end

  def down
    app = Doorkeeper::Application.find_by(name: "Short URL Manager")
    SupportedPermission.find_by(application: app, name: "receive_notifications").destroy
  end
end
