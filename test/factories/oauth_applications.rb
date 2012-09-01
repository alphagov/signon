FactoryGirl.define do
  factory :application, :class => Doorkeeper::Application do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri "https://app.com/callback"
    home_uri "https://app.com/"
    description "Important information about this app"
  end
end
