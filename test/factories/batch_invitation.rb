FactoryBot.define do
  factory :batch_invitation do
    association :user, factory: :admin_user
    trait :with_organisation do
      association :organisation, factory: :organisation
    end
  end
end
