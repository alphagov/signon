FactoryGirl.define do
  factory :application, :class => Doorkeeper::Application do
    ignore do
      with_supported_permissions []
      with_delegatable_supported_permissions []
    end

    sequence(:name) { |n| "Application #{n}" }
    redirect_uri "https://app.com/callback"
    home_uri "https://app.com/"
    description "Important information about this app"

    after(:create) do |app, evaluator|
      evaluator.with_supported_permissions.each do |permission_name|
        create(:supported_permission, application_id: app.id, name: permission_name)
      end

      evaluator.with_delegatable_supported_permissions.each do |permission_name|
        create(:delegatable_supported_permission, application_id: app.id, name: permission_name)
      end
    end
  end
end
