require "test_helper"
require "support/policy_helpers"

class BulkGrantPermissionSetPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "new" do
    should "allow only for superadmins and admins" do
      assert permit?(create(:superadmin_user), User, :new)
      assert permit?(create(:admin_user), User, :new)

      assert forbid?(create(:super_org_admin), User, :new)
      assert forbid?(create(:organisation_admin), User, :new)
      assert forbid?(create(:user), User, :new)
    end
  end
end
