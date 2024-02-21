namespace :oauth_access_grants do
  desc "Delete expired OAuth access grants"
  task delete_expired: "oauth_access_records:delete_expired"
end

namespace :oauth_access_records do
  desc "Delete expired OAuth access grants and tokens"
  task delete_expired: %i[environment set_current_user] do
    %i[access_grant access_token].each do |record_type|
      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type:)

      deleter.delete_expired

      puts "Deleted #{deleter.total_deleted} expired #{deleter.record_class} records"
    end
  end
end
