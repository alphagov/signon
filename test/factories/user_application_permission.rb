FactoryBot.define do
  factory :user_application_permission do
    user
    application
    supported_permission { application.signin_permission }
  end
end
