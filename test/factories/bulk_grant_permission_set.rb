FactoryGirl.define do
  factory :bulk_grant_permission_set do
    transient do
      with_permissions { [create(:supported_permission)] }
    end

    association :user, factory: :admin_user
    after(:build) do |permission_set, evaluator|
      if evaluator.with_permissions
        evaluator.with_permissions.each do |supported_permission|
          permission_set.bulk_grant_permission_set_application_permissions.build(supported_permission: supported_permission)
        end
      end
    end
  end
end
