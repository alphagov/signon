namespace :applications do
  desc "Creates an application(OAuth client)"
  task create: :environment do
    # Create client app
    a = Doorkeeper::Application.create!(
      name: ENV["name"],
      redirect_uri: ENV["redirect_uri"],
      description: ENV["description"],
      home_uri: ENV["home_uri"],
    )
    # Optionally set up supported permissions
    permissions = (ENV["supported_permissions"] || "").split(",")
    permissions.each do |permission|
      SupportedPermission.create(application_id: a.id, name: permission)
    end
    # Done
    puts "Application '#{a.name}' created."
    puts
    puts "config.oauth_id     = '#{a.uid}'"
    puts "config.oauth_secret = '#{a.secret}'"
  end

  desc "Updates domain name for applications, optionally pass CSV of apps to ignore"
  task :migrate_domain, [:apps_to_ignore] => :environment do |_t, args|
    apps_to_ignore = args.any? ? args[:apps_to_ignore].split(",") : []
    raise "Requires OLD_DOMAIN + NEW_DOMAIN specified in environment" unless ENV["OLD_DOMAIN"] && ENV["NEW_DOMAIN"]

    Doorkeeper::Application.where.not(name: apps_to_ignore).find_each do |application|
      %i[redirect_uri home_uri].each do |field|
        new_domain = application[field].gsub(ENV["OLD_DOMAIN"], ENV["NEW_DOMAIN"])
        unless application[field].include? ENV["NEW_DOMAIN"]
          puts "Migrating #{application.name} - #{field} to new domain: #{new_domain}"
          application[field] = new_domain
        end
      end
      application.save!
    end
  end
end
