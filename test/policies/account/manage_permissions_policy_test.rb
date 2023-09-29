require "test_helper"
require "support/policy_helpers"

class Account::ManagePermissionsPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "#show?" do
    %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
      should "permit access for #{user_role} users" do
        current_user = FactoryBot.build(:"#{user_role}_user")

        assert permit?(current_user, nil, :show)
      end
    end

    should "forbid access for normal users" do
      current_user = FactoryBot.build(:user)

      assert forbid?(current_user, nil, :show)
    end
  end
end
