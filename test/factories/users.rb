FactoryBot.define do
  factory :user do
    transient do
      with_permissions {}
      with_signin_permissions_for []
    end

    sequence(:email) { |n| "user#{n}@example.com" }
    password "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    confirmed_at 1.day.ago
    name { "A name is now required" }
    role "normal"

    after(:create) do |user, evaluator|
      if evaluator.with_permissions
        evaluator.with_permissions.each do |app_or_name, permission_names|
          app = if app_or_name.is_a?(String)
                  Doorkeeper::Application.where(name: app_or_name).first!
                else
                  app_or_name
                end
          user.grant_application_permissions(app, permission_names)
        end
      end

      evaluator.with_signin_permissions_for.each do |app_or_name|
        app = if app_or_name.is_a?(String)
                Doorkeeper::Application.where(name: app_or_name).first!
              else
                app_or_name
              end
        user.grant_application_permission(app, 'signin')
      end
    end
  end

  factory :two_step_enabled_user, parent: :user do
    otp_secret_key "Sssshh"
  end

  factory :two_step_flagged_user, parent: :superadmin_user do
    require_2sv true
  end

  factory :user_with_pending_email_change, parent: :user do
    email "old@email.com"
    unconfirmed_email "new@email.com"
    sequence(:confirmation_token) { |n| "#{n}a1s2d3"} # see `token_sent_to` in ConfirmationTokenHelper
    confirmation_sent_at Time.zone.now
  end

  factory :superadmin_user, parent: :user do
    sequence(:email) { |n| "superadmin#{n}@example.com" }
    role "superadmin"
  end

  factory :admin_user, parent: :user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    role "admin"
  end

  factory :super_org_admin, parent: :user_in_organisation do
    role "super_organisation_admin"
  end

  factory :organisation_admin, parent: :user_in_organisation do
    role "organisation_admin"
  end

  factory :suspended_user, parent: :user do
    suspended_at Time.zone.now
    reason_for_suspension "Testing"
  end

  factory :user_in_organisation, parent: :user do
    association :organisation, factory: :organisation
  end

  factory :api_user do
    transient do
      with_permissions {}
    end

    sequence(:email) { |n| "api-#{n}@example.com" }
    password "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    confirmed_at 1.day.ago
    name { "API User" }

    api_user true

    after(:create) do |user, evaluator|
      if evaluator.with_permissions
        evaluator.with_permissions.each do |app_or_name, permission_names|
          app = if app_or_name.is_a?(String)
                  Doorkeeper::Application.where(name: app_or_name).first!
                else
                  app_or_name
                end
          user.grant_application_permissions(app, permission_names)
        end
      end
    end
  end
end
