namespace :applications do

  desc "Creates an application(OAuth client)"
  task :create, [:name, :redirect_uri] => :environment do |t, args|
    a = Doorkeeper::Application.create!(:name => args[:name], :redirect_uri => args[:redirect_uri])
    puts "Application '#{a.name}' created."
    puts 
    puts "config.oauth_id     = '#{a.uid}'"
    puts "config.oauth_secret = '#{a.secret}'"
  end

  desc "Imports applications (OAuth clients) from Sign-on-o-tron1"
  task :import_from_signonotron1 => :environment do
    class OldClient < ActiveRecord::Base
      establish_connection(:signonotron1)
      set_table_name 'oauth_clients'
    end

    class NewApplication < ActiveRecord::Base
      set_table_name 'oauth_applications'
    end

    OldClient.find_each do |old_client|
      puts "Migrating #{old_client.name}(#{old_client.oauth_identifier})"
      a = NewApplication.find_or_initialize_by_uid(old_client.oauth_identifier)
      a.name = old_client.name
      a.secret = old_client.oauth_secret
      a.redirect_uri = old_client.oauth_redirect_uri || ""
      a.save!
    end
  end
end
