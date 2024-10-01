FactoryBot.define do
  factory :supported_permission, aliases: [:non_delegated_supported_permission] do
    sequence(:name) { |n| "Permission ##{n}" }
    association :application, factory: :application
  end

  factory :delegated_supported_permission, parent: :supported_permission do
    delegated { true }
  end
end
