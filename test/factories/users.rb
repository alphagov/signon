FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    confirmed_at 1.day.ago
    name { "A name is now required" }
  end

  factory :user_with_pending_email_change, parent: :user do
    email "old@email.com"
    unconfirmed_email "new@email.com"
    sequence(:confirmation_token) { |n| "#{n}a1s2d3"}
    confirmation_sent_at Time.zone.now
  end

  factory :admin_user, parent: :user do
    role "admin"
  end

  factory :user_in_organisation, parent: :user do
    ignore do
      organisations_count 1
    end

    after_create do |user, evaluator|
      FactoryGirl.create_list(:organisation, evaluator.organisations_count, users: [user])
    end
  end
end
