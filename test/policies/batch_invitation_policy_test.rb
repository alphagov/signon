require "test_helper"
require "support/policy_helpers"

class BatchInvitationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "new" do
    should "allow superadmins and admins to create new batch uploads" do
      assert permit?(create(:superadmin_user), BatchInvitation.new, :new)
      assert permit?(create(:admin_user), BatchInvitation.new, :new)
    end

    should "forbid organisation admins to create new batch uploads even within their organisation subtree" do
      organisation_admin = create(:organisation_admin)

      assert forbid?(organisation_admin, BatchInvitation.new, :new)
      assert forbid?(organisation_admin, BatchInvitation.new(organisation_id: create(:organisation).id), :new)
      assert forbid?(organisation_admin, BatchInvitation.new(organisation_id: organisation_admin.organisation_id), :new)
    end

    should "forbid for normal users" do
      forbid?(create(:user), BatchInvitation.new, :new)
    end
  end

  context "assign_organisation_from_csv" do
    should "allow only for superadmins and admins" do
      assert permit?(create(:superadmin_user), User, :assign_organisation_from_csv)
      assert permit?(create(:admin_user), User, :assign_organisation_from_csv)

      assert forbid?(create(:super_org_admin), User, :assign_organisation_from_csv)
      assert forbid?(create(:organisation_admin), User, :assign_organisation_from_csv)
      assert forbid?(create(:user), User, :assign_organisation_from_csv)
    end
  end
end
