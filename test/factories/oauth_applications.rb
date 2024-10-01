FactoryBot.define do
  factory :application, class: Doorkeeper::Application do
    transient do
      with_non_delegated_supported_permissions { [] }
      with_non_delegated_supported_permissions_not_grantable_from_ui { [] }
      with_delegated_supported_permissions { [] }
      with_delegated_supported_permissions_not_grantable_from_ui { [] }
    end

    sequence(:name) { |n| "Application #{n}" }
    redirect_uri { "https://app.com/callback" }
    home_uri { "https://app.com/" }
    description { "Important information about this app" }
    supports_push_updates { false }

    after(:create) do |app, evaluator|
      evaluator.with_non_delegated_supported_permissions.each do |permission_name|
        app.signin_permission.update(delegated: false) && next if permission_name == SupportedPermission::SIGNIN_NAME

        create(:supported_permission, application: app, name: permission_name)
      end

      evaluator.with_non_delegated_supported_permissions_not_grantable_from_ui.each do |permission_name|
        app.signin_permission.update(delegated: false, grantable_from_ui: false) && next if permission_name == SupportedPermission::SIGNIN_NAME

        create(:supported_permission, application: app, name: permission_name, grantable_from_ui: false)
      end

      evaluator.with_delegated_supported_permissions.each do |permission_name|
        next if permission_name == SupportedPermission::SIGNIN_NAME

        create(:delegated_supported_permission, application: app, name: permission_name)
      end

      evaluator.with_delegated_supported_permissions_not_grantable_from_ui.each do |permission_name|
        app.signin_permission.update(grantable_from_ui: false) && next if permission_name == SupportedPermission::SIGNIN_NAME

        create(:delegated_supported_permission, application: app, name: permission_name, grantable_from_ui: false)
      end
    end
  end
end
