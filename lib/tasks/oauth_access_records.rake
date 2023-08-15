namespace :oauth_access_grants do
  desc "Delete expired OAuth access grants"
  task delete_expired: "oauth_access_records:delete_expired"
end

namespace :oauth_access_records do
  desc "Delete expired OAuth access grants and tokens"
  task delete_expired: :environment do
    [Doorkeeper::AccessGrant, Doorkeeper::AccessToken].each do |klass|
      deleter = ExpiredOauthAccessRecordsDeleter.new(klass:)

      deleter.delete_expired

      puts "Deleted #{deleter.total_deleted} expired #{klass} records"
    end
  end
end
