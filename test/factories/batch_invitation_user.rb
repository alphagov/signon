FactoryBot.define do
  factory :batch_invitation_user do
    name { "Mark France" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
