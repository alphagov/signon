namespace :users do
  desc "Create a new user (specify name and email in environment)"
  task create: :environment do
    raise "Requires name, email and applications specified in environment" unless ENV['name'] && ENV['email'] && ENV['applications']

    user_creator = UserCreator.new(ENV['name'], ENV['email'], ENV['applications'])
    user_creator.create_user!

    puts "User created: user.name <#{user_creator.user.name}>"
    puts "              user.email <#{user_creator.user.email}>"
    puts "              signin permissions for: '#{user_creator.applications.map(&:name).join("', '")}' "
    puts "              follow this link to set a password: #{user_creator.invitation_url}"
  end

  desc "Remind users that their account will get suspended"
  task send_suspension_reminders: :environment do
    with_lock('signon:users:send_suspension_reminders') do
      suspension_reminder_mailing_list = InactiveUsersSuspensionReminderMailingList.new(User::SUSPENSION_THRESHOLD_PERIOD).generate
      suspension_reminder_mailing_list.each do |days_to_suspension, users|
        InactiveUsersSuspensionReminder.new(users, days_to_suspension).send_reminders
        puts "InactiveUsersSuspensionReminder: Sent emails to #{users.count} users to remind them that their account will be suspended in #{days_to_suspension} days"
      end
    end
  end

  desc "Suspend users who have not signed-in for 45 days"
  task suspend_inactive: :environment do
    with_lock('signon:users:suspend_inactive') do
      count = InactiveUsersSuspender.new.suspend
      puts "#{count} users were suspended because they had not logged in since #{User::SUSPENSION_THRESHOLD_PERIOD.inspect}"
    end
  end

  desc "Suspend a user's access to the site (specify email in environment)"
  task suspend: :environment do
    raise "Requires email specified in environment" unless ENV['email']
    user = User.find_by_email(ENV['email'])
    raise "Couldn't find user" unless user
    user.suspend
    puts "User account suspended"
  end

  desc "Unsuspend a user's access to the site (specify email in environment)"
  task unsuspend: :environment do
    raise "Requires email specified in environment" unless ENV['email']
    user = User.find_by_email(ENV['email'])
    raise "Couldn't find user" unless user
    user.unsuspend
    puts "User account unsuspended"
  end

  desc "Push user permission information to applications used by the user"
  task push_permissions: :environment do
    User.find_each { |user| PermissionUpdater.perform_on(user) }
  end

  desc "Exports user permissions by application(s) in csv format"
  task export_permissions: :environment do
    raise "Requires ENV variable EXPORT_DIR to be set to a valid directory path" if ENV['EXPORT_DIR'].blank?
    raise "Requires ENV variable APPLICATIONS to be set to a string containing comma-separated application names" if ENV['APPLICATIONS'].blank?

    application_names = ENV['APPLICATIONS'].split(',').map(&:strip).map(&:titleize)
    UserPermissionsExporter.new(ENV['EXPORT_DIR'], Logger.new(STDOUT)).export(application_names)
  end

  desc "Exports user roles in csv format"
  task export_roles: :environment do
    raise "Requires ENV variable EXPORT_DIR to be set to a valid directory path" if ENV['EXPORT_DIR'].blank?

    UserPermissionsExporter.new(ENV['EXPORT_DIR'], Logger.new(STDOUT)).export_signon
  end

  desc "Grant access to Content Preview for all active users who don't have it"
  task grant_content_preview_access: :environment do
    if content_preview = Doorkeeper::Application.find_by(name: "Content Preview")
      User.web_users.not_suspended.find_each do |user|
        puts "Checking user ##{user.id}: #{user.name}"
        next if user.application_permissions.map(&:application).include?(content_preview)

        puts "-- Adding signin permission for #{content_preview.name}"
        user.grant_application_permission(content_preview, "signin")

        if content_preview.supports_push_updates?
          PermissionUpdater.perform_async(user.uid, content_preview.id)
        end
      end
    else
      raise "Could not find an application called 'Content Preview'"
    end
  end

  desc "Migrates user permissions from source to target application"
  task migrate_permissions: :environment do
    source_application = ENV["SOURCE"]
    target_application = ENV["TARGET"]

    unless source_application && target_application
      raise "Please supply SOURCE and TARGET application names"
    end

    UserPermissionMigrator.migrate(source: source_application, target: target_application)
  end
end
