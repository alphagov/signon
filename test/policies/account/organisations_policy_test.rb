require "test_helper"
require "support/policy_helpers"

class Account::OrganisationsPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "show?" do
    should "allow logged in users to see show irrespective of their role" do
      assert permit?(build(:user), nil, :show)
    end

    should "not allow anonymous visitors to see show" do
      assert forbid?(nil, nil, :show)
    end
  end

  context "update_organisation?" do
    %i[superadmin admin].each do |user_role|
      should "be permitted for #{user_role} users" do
        user = FactoryBot.build(:"#{user_role}_user")

        assert permit?(user, nil, :update_organisation)
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
      should "be forbidden for #{user_role} users" do
        user = FactoryBot.build(:"#{user_role}_user")

        assert forbid?(user, nil, :update_organisation)
      end
    end
  end
end
