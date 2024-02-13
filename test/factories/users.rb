FactoryBot.define do
  factory :user, aliases: [:normal_user] do
    transient do
      with_permissions { {} }
      with_signin_permissions_for { [] }
    end

    sequence(:email) { |n| "user#{n}@example.com" }
    password { "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z" }
    confirmed_at { 1.day.ago }
    sequence(:name) { |n| "user-name-#{n}" }
    role { Roles::Normal.role_name }

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
        user.grant_application_signin_permission(app)
      end
    end

    trait :with_expired_confirmation_token do
      confirmation_token { "expired-token" }
      confirmation_sent_at { Devise.confirm_within.ago - 1.day }
    end

    trait :in_organisation do
      association :organisation, factory: :organisation
    end

    trait :in_gds_organisation do
      association :organisation, factory: :gds_organisation
    end
  end

  factory :two_step_enabled_user, parent: :user do
    require_2sv { true }
    otp_secret_key { "Sssshh" }
  end

  factory :two_step_enabled_organisation_admin, parent: :organisation_admin_user do
    require_2sv { true }
    otp_secret_key { "Sssshh" }
  end

  factory :two_step_mandated_superadmin_user, parent: :superadmin_user do
    require_2sv { true }
  end

  factory :two_step_mandated_user, parent: :user do
    require_2sv { true }
  end

  factory :two_step_exempted_user, parent: :user do
    require_2sv { false }
    reason_for_2sv_exemption { "accessibility reasons" }
    expiry_date_for_2sv_exemption { (Time.zone.today + 1).to_date }
  end

  trait :with_pending_email_change do
    email { "old@email.com" }
    unconfirmed_email { "new@email.com" }
    sequence(:confirmation_token) { |n| "#{n}a1s2d3" } # see `token_sent_to` in ConfirmationTokenHelper
    confirmation_sent_at { Time.current }
  end

  factory :user_with_pending_email_change, parent: :user, traits: [:with_pending_email_change]

  factory :superadmin_user, parent: :user do
    sequence(:email) { |n| "superadmin#{n}@example.com" }
    role { Roles::Superadmin.role_name }
  end

  factory :admin_user, parent: :user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    role { Roles::Admin.role_name }
  end

  factory :super_organisation_admin_user, parent: :user_in_organisation do
    role { Roles::SuperOrganisationAdmin.role_name }
  end

  factory :organisation_admin_user, parent: :user_in_organisation do
    role { Roles::OrganisationAdmin.role_name }
  end

  trait :invited do
    invitation_sent_at { 1.minute.ago }
    invitation_accepted_at { nil }
  end

  factory :invited_user, parent: :user, traits: [:invited]

  factory :active_user, parent: :invited_user do
    invitation_accepted_at { Time.current }
  end

  factory :suspended_user, parent: :user do
    suspended_at { Time.current }
    reason_for_suspension { "Testing" }
  end

  factory :locked_user, parent: :user do
    locked_at { Time.current }
  end

  factory :user_in_organisation, parent: :user, traits: [:in_organisation]

  factory :api_user do
    transient do
      with_permissions { {} }
    end

    sequence(:email) { |n| "api-#{n}@example.com" }
    password { "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z" }
    confirmed_at { 1.day.ago }
    name { "API User" }

    api_user { true }

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

def api_user_with_token(name, token_count: 2)
  FactoryBot.create(:api_user, name:) do |api_user|
    token_count.times do
      app = FactoryBot.create(:application)
      FactoryBot.create(
        :access_token, resource_owner_id: api_user.id, application_id: app.id
      )
    end
  end
end
