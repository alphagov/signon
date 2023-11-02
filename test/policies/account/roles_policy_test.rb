require "test_helper"
require "support/policy_helpers"

class Account::RolesPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "edit?" do
    should "allow logged in users to see edit irrespective of their role" do
      assert permit?(build(:user), nil, :edit)
    end

    should "not allow anonymous visitors to see edit" do
      assert forbid?(nil, nil, :edit)
    end
  end

  context "update?" do
    %i[superadmin].each do |user_role|
      should "be permitted for #{user_role} users" do
        user = FactoryBot.build(:"#{user_role}_user")

        assert permit?(user, nil, :update)
      end
    end

    %i[admin super_organisation_admin organisation_admin normal].each do |user_role|
      should "be forbidden for #{user_role} users" do
        user = FactoryBot.build(:"#{user_role}_user")

        assert forbid?(user, nil, :update)
      end
    end
  end
end
