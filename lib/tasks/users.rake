namespace :users do
  desc "Create a new user (specify name and email in environment)"
  task :create => :environment do
    raise "Requires name, email and applications specified in environment" unless ENV['name'] && ENV['email'] && ENV['applications']

    applications = ENV['applications'].split(',').uniq.map do |application_name|
      Doorkeeper::Application.find_by_name!(application_name)
    end

    user = User.invite!(name: ENV['name'].dup, email: ENV['email'].dup)
    applications.each do |application|
      user.grant_permission(application, 'signin')
    end

    invitation_url = "#{Plek.current.find("signon")}/users/invitation/accept?invitation_token=#{user.invitation_token}"
    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "              signin permissions for: '#{applications.map(&:name).join(%q{', '})}' "
    puts "              follow this link to set a password: #{invitation_url}"
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

  desc "Fix signin permission boolean"
  task :fix_signin => :environment do
    permissions_to_update = []
    Permission.all.each do |permission|
      permissions_to_update << permission.id if permission.permissions.include?("signin")
    end
    puts "Fixing #{permissions_to_update.count} permissions"
    Permission.where(id: permissions_to_update).update_all(signin_permission: true)
  end
end