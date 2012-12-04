namespace :users do
  desc "Create a new user (specify name, email and optional password in environment)"
  task :create => :environment do
    raise "Requires name and email specified in environment" unless ENV['name'] && ENV['email']

    user = User.invite!(name: ENV['name'].dup, email: ENV['email'].dup)
    invitation_url = "#{Plek.current.find("signon")}/users/invitation/accept?invitation_token=#{user.invitation_token}"
    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "              follow this link to set a password: #{invitation_url}"
  end

  desc "Suspend a user's access to the site (specify email in environment)"
  task :suspend => :environment do
    raise "Requires email specified in environment" unless ENV['email']
    user = User.find_by_email(ENV['email'])
    raise "Couldn't find user" unless user
    user.suspend!
    puts "User account suspended"
  end

  desc "Unsuspend a user's access to the site (specify email in environment)"
  task :unsuspend => :environment do
    raise "Requires email specified in environment" unless ENV['email']
    user = User.find_by_email(ENV['email'])
    raise "Couldn't find user" unless user
    user.unsuspend!
    puts "User account unsuspended"
  end

  desc "Load all user records from signontron1"
  task :import_from_signonotron1 => :environment do
    class OldUser < ActiveRecord::Base
      establish_connection(:signonotron1)
      set_table_name 'users'
    end

    class NewUser < ActiveRecord::Base
      set_table_name 'users'
    end

    OldUser.find_each do |old_user|
      puts "Migrating #{old_user.email}"
      u = NewUser.find_or_initialize_by_email(old_user.email)
      u.attributes = old_user.attributes.select {|k,v| u.has_attribute? k}
      u.save!
    end
  end
end