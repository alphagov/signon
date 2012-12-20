namespace :applications do

  desc "Creates an application(OAuth client)"
  task :create => :environment do 
    a = Doorkeeper::Application.create!(
      name: ENV['name'],
      redirect_uri: ENV['redirect_uri'],
      description: ENV['description'],
      home_uri: ENV['home_uri']
    )
    puts "Application '#{a.name}' created."
    puts 
    puts "config.oauth_id     = '#{a.uid}'"
    puts "config.oauth_secret = '#{a.secret}'"
  end
end
