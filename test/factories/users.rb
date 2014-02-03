FactoryGirl.define do
  factory :user do
    ignore do
      with_permissions {}
      with_signin_permissions_for []
    end

    sequence(:email) { |n| "user#{n}@example.com" }
    password "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    confirmed_at 1.day.ago
    name { "A name is now required" }

    after(:create) do |user, evaluator|
      evaluator.with_permissions.each do |app_or_name, permission_names|
        app = if app_or_name.is_a?(String)
                Doorkeeper::Application.where(name: app_or_name).first!
              else
                app_or_name
              end
        create(:permission, application: app, user: user, permissions: permission_names)
      end if evaluator.with_permissions

      evaluator.with_signin_permissions_for.each do |app_or_name|
        app = if app_or_name.is_a?(String)
                Doorkeeper::Application.where(name: app_or_name).first!
              else
                app_or_name
              end
        create(:permission, application: app, user: user)
      end
    end
  end

  factory :user_with_pending_email_change, parent: :user do
    email "old@email.com"
    unconfirmed_email "new@email.com"
    sequence(:confirmation_token) { |n| "#{n}a1s2d3"}
    confirmation_sent_at Time.zone.now
  end

  factory :admin_user, parent: :user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    role "admin"
  end

  factory :superadmin_user, parent: :user do
    sequence(:email) { |n| "superadmin#{n}@example.com" }
    role "superadmin"
  end

  factory :api_user, parent: :user do
    sequence(:email) { |n| "api-#{n}@example.com" }
    api_user true
  end

  factory :organisation_admin, parent: :user_in_organisation do
    role "organisation_admin"
  end

  factory :suspended_user, parent: :user do
    suspended_at Time.zone.now
  end

  factory :user_in_organisation, parent: :user do
    association :organisation, factory: :organisation
  end
end
