namespace :oauth_access_grants do
  desc "Delete expired OAuth access grants"
  task delete_expired: 'oauth_access_records:delete_expired'
end

namespace :oauth_access_records do
  desc "Delete expired OAuth access grants and tokens"
  task delete_expired: :environment do
    klasses = [Doorkeeper::AccessGrant, Doorkeeper::AccessToken]
    klasses.each do |klass|
      ids = [nil]

      count = 0

      until ids.empty?
        ids = klass
          .where('expires_in is not null AND DATE_ADD(created_at, INTERVAL expires_in second) < ?', Time.zone.now)
          .limit(1000)
          .pluck(:id)

        count += ids.size

        klass.where(id: ids).delete_all
      end

      puts "Deleted #{count} expired #{klass} records"
    end
  end
end
