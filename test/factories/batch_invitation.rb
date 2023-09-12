FactoryBot.define do
  factory :batch_invitation do
    association :user, factory: :admin_user
    trait :with_organisation do
      association :organisation, factory: :organisation
    end

    trait :in_progress do
      outcome { nil }

      has_permissions
    end

    trait :has_permissions do
      after(:create) do |batch_invitation|
        unless batch_invitation.has_permissions?
          batch_invitation.supported_permissions << create(:supported_permission)
          batch_invitation.save!
        end
      end
    end
  end
end
