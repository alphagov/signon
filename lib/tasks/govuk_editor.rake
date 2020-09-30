namespace :govuk_editor do
  desc "Assign govuk_editor permission to everyone who has access to Publisher."
  task assign: :environment do
    application = Doorkeeper::Application.find_by!(name: "Publisher")
    permission = SupportedPermission.find_by!(application: application, name: "govuk_editor")

    users = User
      .with_status(User::USER_STATUS_ACTIVE)
      .joins(:supported_permissions)
      .where(supported_permissions: { application: application })
      .distinct

    users.find_each do |user|
      puts "#{user.name} #{user.email}"
      user.application_permissions.create!(supported_permission: permission)
    end
  end
end
