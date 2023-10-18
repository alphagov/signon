require "date"

namespace :users do
  desc "Remind users that their account will get suspended"
  task send_suspension_reminders: :environment do
    include VolatileLock::DSL

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
    include VolatileLock::DSL

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
    UserPermissionsExporter.new(ENV["EXPORT_DIR"], Logger.new($stdout)).export(application_names)
  end

  desc "Exports user roles in csv format"
  task export_roles: :environment do
    raise "Requires ENV variable EXPORT_DIR to be set to a valid directory path" if ENV["EXPORT_DIR"].blank?

    UserPermissionsExporter.new(ENV["EXPORT_DIR"], Logger.new($stdout)).export_signon
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

    UserSuspensionsExporter.call(ENV["EXPORT_DIR"], users_since_date, suspensions_since_date, Logger.new($stdout))
  end

  desc "Grant all active and suspended users access to an application, who don't have access"
  task :grant_application_access, [:application] => :environment do |_t, args|
    application = Doorkeeper::Application.find_by(name: args.application)

    raise "Couldn't find application: '#{args.application}'" unless application

    SigninPermissionGranter.call(
      users: User.web_users.not_suspended.find_each,
      application:,
    )
  end

  desc "Revoke all permissions for all users of an application"
  task :revoke_application_access, [:application] => :environment do |_t, args|
    application = Doorkeeper::Application.find_by(name: args.application)

    raise "Couldn't find application: '#{args.application}'" unless application

    UserApplicationPermission.where(application:).destroy_all
  end

  desc "Grant all users in an organisation access to an application"
  task :grant_application_access_for_org, %i[application org] => :environment do |_t, args|
    application = Doorkeeper::Application.find_by(name: args.application)
    raise "Couldn't find application: '#{args.application}'" unless application

    organisation = Organisation.find_by(slug: args.org)
    raise "Couldn't find organisation (by slug): '#{args.org}'" unless organisation

    SigninPermissionGranter.call(
      users: organisation.users.web_users.find_each,
      application:,
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

  desc "Sets 2sv on all existing users by organisation"
  task :set_2sv_by_org, [:org] => :environment do |_t, args|
    organisation = Organisation.find_by(slug: args.org)
    raise "Couldn't find organisation: '#{args.org}'" unless organisation

    users_to_update = User.where(organisation_id: organisation.id, require_2sv: false)
                          .where(reason_for_2sv_exemption: nil)

    puts "found #{users_to_update.size} users without 2sv in organsation #{args.org} to set require 2sv flag on"

    users_to_update.each { |user| user.update(require_2sv: true) }
  end

  desc "Sets 2sv on an organisation"
  task :set_2sv_for_org, [:org] => :environment do |_t, args|
    organisation = Organisation.find_by(slug: args.org)
    raise "Couldn't find organisation: '#{args.org}'" unless organisation

    organisation.update!(require_2sv: true)

    puts "mandated 2sv for organsation #{args.org}"
  end

  desc "Sets 2sv on all users by email domain"
  task :set_2sv_by_email_domain, [:domain] => :environment do |_t, args|
    users_to_update = User.where("email LIKE ?", "%#{args.domain}")
                          .where(require_2sv: false)
                          .where(reason_for_2sv_exemption: nil)

    puts "found #{users_to_update.size} users without 2sv with email domain #{args.domain} to set require 2sv flag on"

    users_to_update.each { |user| user.update(require_2sv: true) }
  end

  desc "Sets 2sv on all organisation admin and organisation superadmin users"
  task set_2sv_for_org_admins: :environment do
    org_admin_users = User.where(role: Roles::OrganisationAdmin.role_name)
    super_org_admin_users = User.where(role: Roles::SuperOrganisationAdmin.role_name)

    users_to_update = org_admin_users + super_org_admin_users

    users_to_update.each { |user| user.update(require_2sv: true) }
  end

  desc "Deletes all web users who've never signed in and were invited at least 90 days ago"
  task delete_expired_never_signed_in: :environment do
    ExpiredNotSignedInUserDeleter.new.delete
  end
end
