namespace :oauth_access_grants do
  desc "Delete expired OAuth access grants"
  task delete_expired: :environment do
    count = Doorkeeper::AccessGrant
      .where('expires_in is not null AND DATE_ADD(created_at, INTERVAL expires_in second) < ?', Time.zone.now)
      .delete_all

    puts "Done. Deleted #{count} expired OAuth access grants."
  end
end
