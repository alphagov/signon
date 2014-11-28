namespace :users do
  desc "Create a new user (specify name and email in environment)"
  task :create => :environment do
    raise "Requires name, email and applications specified in environment" unless ENV['name'] && ENV['email'] && ENV['applications']

    applications = ENV['applications'].split(',').uniq.map do |application_name|
      Doorkeeper::Application.find_by_name!(application_name)
    end

    user = User.invite!(name: ENV['name'].dup, email: ENV['email'].dup)
    permissions = ENV.fetch('permissions', '').split(',').uniq

    applications.each do |application|
      unsupported_permissions = permissions - application.supported_permission_strings
      if unsupported_permissions.any?
        raise UnsupportedPermissionError, "Cannot grant '#{unsupported_permissions.join("', '")}' permission(s), they are not supported by the '#{application.name}' application"
      end
      user.grant_permission(application, 'signin')
    end

    invitation_url = "#{Plek.current.find("signon")}/users/invitation/accept?invitation_token=#{user.invitation_token}"
    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "              signin permissions for: '#{applications.map(&:name).join(%q{', '})}' "
    puts "              follow this link to set a password: #{invitation_url}"
  end

  desc "Remind users that their account will get suspended"
  task :send_suspension_reminders => :environment do
    with_lock('signon:users:send_suspension_reminders') do
      suspension_reminder_mailing_list = InactiveUsersSuspensionReminderMailingList.new(User::SUSPENSION_THRESHOLD_PERIOD).generate
      suspension_reminder_mailing_list.each do |days_to_suspension, users|
        InactiveUsersSuspensionReminder.new(users, days_to_suspension).send_reminders
        puts "InactiveUsersSuspensionReminder: Sent emails to #{users.count} users to remind them that their account will be suspended in #{days_to_suspension} days"
      end
    end
  end

  desc "Suspend users who have not signed-in for 45 days"
  task :suspend_inactive => :environment do
    with_lock('signon:users:suspend_inactive') do
      count = InactiveUsersSuspender.new.suspend
      puts "#{count} users were suspended because they had not logged in since #{User::SUSPENSION_THRESHOLD_PERIOD.inspect}"
    end
  end

  desc "Suspend a user's access to the site (specify email in environment)"
  task :suspend => :environment do
    raise "Requires email specified in environment" unless ENV['email']
    user = User.find_by_email(ENV['email'])
    raise "Couldn't find user" unless user
    user.suspend
    puts "User account suspended"
  end

  desc "Unsuspend a user's access to the site (specify email in environment)"
  task :unsuspend => :environment do
    raise "Requires email specified in environment" unless ENV['email']
    user = User.find_by_email(ENV['email'])
    raise "Couldn't find user" unless user
    user.unsuspend
    puts "User account unsuspended"
  end

  desc "Push user permission information to applications passed as a comma-separated string in ENV variable 'APPLICATIONS'"
  task :push_permissions => :environment do
    raise "Requires ENV variable APPLICATIONS to be set to a string containing comma-separated application names" if ENV['APPLICATIONS'].blank?

    application_names = ENV['APPLICATIONS'].split(',').map(&:strip).map(&:titleize)
    applications = Doorkeeper::Application.where(name: application_names)
    puts "About to push user permission information to #{applications.map(&:name).to_sentence}"

    application_users = applications.inject({}) do |result, application|
      result[application] = User.where(id: application.permissions.pluck(:user_id).uniq)
      result
    end
    application_users.each do |application, users|
      puts "Pushing permission information of #{users.count} users to #{application.name}"
      users.each { |user| PermissionUpdater.perform_async(user.uid, application.id) }
    end
  end

  desc "Exports user permissions by application(s) in csv format"
  task :export_permissions, [:export_dir, :apps] => :environment do |t, args|
    UserPermissionsExporter.new(args[:export_dir], Logger.new(STDOUT)).export(args[:apps].split)
  end

  desc "Exports user roles in csv format"
  task :export_roles, [:export_dir] => :environment do |t, args|
    UserPermissionsExporter.new(args[:export_dir], Logger.new(STDOUT)).export_signon
  end
end
