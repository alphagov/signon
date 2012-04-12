namespace :applications do

  desc "Imports applications (clients) from Sign-on-o-tron1"
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
