namespace :applications do

  desc "Creates an application(OAuth client)"
  task :create, [:name, :redirect_uri, :description, :home_uri] => :environment do |t, args|
    a = Doorkeeper::Application.create!(
      name: args[:name],
      redirect_uri: args[:redirect_uri],
      description: args[:description],
      home_uri: args[:home_uri]
    )
    puts "Application '#{a.name}' created."
    puts 
    puts "config.oauth_id     = '#{a.uid}'"
    puts "config.oauth_secret = '#{a.secret}'"
  end
end
