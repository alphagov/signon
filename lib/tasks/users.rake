require "date"

namespace :users do
  desc "Create a new user (specify name and email in environment)"
  task create: :environment do
    raise "Requires name, email and applications specified in environment" unless ENV["name"] && ENV["email"] && ENV["applications"]

    user_creator = UserCreator.new(ENV["name"], ENV["email"], ENV["applications"])
    user_creator.create_user!

    puts "User created: user.name <#{user_creator.user.name}>"
    puts "              user.email <#{user_creator.user.email}>"
    puts "              signin permissions for: '#{user_creator.applications.map(&:name).join("', '")}' "
    puts "              follow this link to set a password: #{user_creator.invitation_url}"
  end

  desc "Remind users that their account will get suspended"
  task send_suspension_reminders: :environment do
    with_lock("signon:users:send_suspension_reminders") do
      suspension_reminder_mailing_list = InactiveUsersSuspensionReminderMailingList.new(User::SUSPENSION_THRESHOLD_PERIOD).generate
      suspension_reminder_mailing_list.each do |days_to_suspension, users|
        InactiveUsersSuspensionReminder.new(users, days_to_suspension).send_reminders
        puts "InactiveUsersSuspensionReminder: Sent emails to #{users.count} users to remind them that their account will be suspended in #{days_to_suspension} days"
      end
    end
  end

  desc "Suspend users who have not signed-in for 45 days"
  task suspend_inactive: :environment do
    with_lock("signon:users:suspend_inactive") do
      count = InactiveUsersSuspender.new.suspend
      puts "#{count} users were suspended because they had not logged in since #{User::SUSPENSION_THRESHOLD_PERIOD.inspect}"
    end
  end

  desc "Suspend a user's access to the site (specify email in environment)"
  task suspend: :environment do
    raise "Requires email specified in environment" unless ENV["email"]

    user = User.find_by(email: ENV["email"])
    raise "Couldn't find user" unless user

    user.suspend
    puts "User account suspended"
  end

  desc "Unsuspend a user's access to the site (specify email in environment)"
  task unsuspend: :environment do
    raise "Requires email specified in environment" unless ENV["email"]

    user = User.find_by(email: ENV["email"])
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
    raise "Requires ENV variable EXPORT_DIR to be set to a valid directory path" if ENV["EXPORT_DIR"].blank?
    raise "Requires ENV variable APPLICATIONS to be set to a string containing comma-separated application names" if ENV["APPLICATIONS"].blank?

    application_names = ENV["APPLICATIONS"].split(",").map(&:strip).map(&:titleize)
    UserPermissionsExporter.new(ENV["EXPORT_DIR"], Logger.new(STDOUT)).export(application_names)
  end

  desc "Exports user roles in csv format"
  task export_roles: :environment do
    raise "Requires ENV variable EXPORT_DIR to be set to a valid directory path" if ENV["EXPORT_DIR"].blank?

    UserPermissionsExporter.new(ENV["EXPORT_DIR"], Logger.new(STDOUT)).export_signon
  end

  desc "Exports users which have been auto-suspended since the given date, and details of their unsuspension"
  task export_auto_suspended_users: :environment do
    raise "Requires ENV variable EXPORT_DIR to be set to a valid directory path" if ENV["EXPORT_DIR"].blank?

    if ENV["DATE"].blank?
      raise "Requires ENV variable USERS_SINCE to be set to a valid date" if ENV["USERS_SINCE"].blank?

      users_since_date = Date.parse(ENV["USERS_SINCE"])

      raise "Requires ENV variable SUSPENSIONS_SINCE to be set to a valid date" if ENV["SUSPENSIONS_SINCE"].blank?

      suspensions_since_date = Date.parse(ENV["SUSPENSIONS_SINCE"])
    else
      users_since_date = Date.parse(ENV["DATE"])
      suspensions_since_date = Date.parse(ENV["DATE"])
    end

    raise "Requires ENV variable USERS_SINCE to be set to a valid date" unless users_since_date
    raise "Requires ENV variable SUSPENSIONS_SINCE to be set to a valid date" unless suspensions_since_date

    UserSuspensionsExporter.call(ENV["EXPORT_DIR"], users_since_date, suspensions_since_date, Logger.new(STDOUT))
  end

  desc "Grant all active and suspended users access to an application, who don't have access"
  task :grant_application_access, [:application] => :environment do |_t, args|
    application = Doorkeeper::Application.find_by(name: args.application)

    raise "Couldn't find application: '#{args.application}'" unless application

    SigninPermissionGranter.call(
      users: User.web_users.not_suspended.find_each,
      application: application,
    )
  end

  desc "Revoke all permissions for all users of an application"
  task :revoke_application_access, [:application] => :environment do |_t, args|
    application = Doorkeeper::Application.find_by(name: args.application)

    raise "Couldn't find application: '#{args.application}'" unless application

    UserApplicationPermission.where(application: application).destroy_all
  end

  desc "Grant all active users in an organisation access to an application"
  task :grant_application_access_for_org, %i[application org] => :environment do |_t, args|
    application = Doorkeeper::Application.find_by(name: args.application)
    raise "Couldn't find application: '#{args.application}'" unless application

    organisation = Organisation.find_by(slug: args.org)
    raise "Couldn't find organisation (by slug): '#{args.org}'" unless organisation

    SigninPermissionGranter.call(
      users: organisation.users.web_users.find_each,
      application: application,
    )
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
