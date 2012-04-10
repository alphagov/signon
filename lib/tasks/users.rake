namespace :users do
  desc "Create a new user (specify name, email and optional password in environment)"
  task :create => :environment do
    require 'securerandom'
    raise "Requires name and email specified in environment" unless ENV['name'] && ENV['email']
    default_password = ENV['password'].to_s.strip
    default_password = SecureRandom.urlsafe_base64 if default_password == ''
    user_params = {
      :name => ENV['name'],
      :email => ENV['email'],
      # :github => (ENV['github'] || nil),
      # :twitter => (ENV['twitter'] || nil),
      :password => "#{default_password}",
      :password_confirmation => "#{default_password}",
      :uid => SecureRandom.urlsafe_base64
    }

    params = Hash[user_params.reject { |k, v| v.nil? }.collect { |k, v| [k, v.dup] }]
    user = User.create!(params)
    user.send_reset_password_instructions
    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "              user.password <#{default_password}>" if ENV['password']
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
end