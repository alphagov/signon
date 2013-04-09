FactoryGirl.define do
  factory :batch_invitation do
    association :user, factory: :admin_user
  end
end
