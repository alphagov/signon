class SigninPermissionGranter
  def self.call(users:, application:)
    users.each do |user|
      puts "Checking user ##{user.id}: #{user.name}"
      next if user.application_permissions.map(&:application).include?(application)

      puts "-- Adding signin permission for #{application.name}"
      user.grant_application_permission(application, "signin")

      if application.supports_push_updates?
        PermissionUpdater.perform_later(user.uid, application.id)
      end
    end
  end
end
