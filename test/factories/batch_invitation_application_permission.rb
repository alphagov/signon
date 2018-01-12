FactoryBot.define do
  factory :batch_invitation_application_permission do
    association :batch_invitation, factory: :batch_invitation
  end
end
