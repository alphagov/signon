FactoryBot.define do
  factory :access_grant, class: Doorkeeper::AccessGrant do
    sequence(:resource_owner_id) { |n| n }
    application
    expires_in { 2.hours }
    redirect_uri { "https://app.com/callback" }
  end
end
