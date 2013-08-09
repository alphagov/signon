namespace :applications do

  desc "Creates an application(OAuth client)"
  task :create => :environment do 
    # Create client app
    a = Doorkeeper::Application.create!(
      name: ENV['name'],
      redirect_uri: ENV['redirect_uri'],
      description: ENV['description'],
      home_uri: ENV['home_uri']
    )
    # Optionally set up supported permissions
    permissions = (ENV['supported_permissions'] || '').split(',')
    permissions.each do |permission|
      SupportedPermission.create(:application_id => a.id, :name => permission)
    end
    # Done
    puts "Application '#{a.name}' created."
    puts 
    puts "config.oauth_id     = '#{a.uid}'"
    puts "config.oauth_secret = '#{a.secret}'"
  end
end
