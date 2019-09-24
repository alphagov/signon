require "test_helper"
require "support/policy_helpers"

class OrganisationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "index" do
    should "allow only for superadmins and admins" do
      assert permit?(create(:superadmin_user), User, :index)
      assert permit?(create(:admin_user), User, :index)

      assert forbid?(create(:super_org_admin), User, :index)
      assert forbid?(create(:organisation_admin), User, :index)
      assert forbid?(create(:user), User, :index)
    end
  end

  context "can_assign" do
    should "allow superadmins and admins to assign a user to any organisation" do
      assert permit?(create(:user_in_organisation, role: "superadmin"), build(:organisation), :can_assign)
      assert permit?(create(:user_in_organisation, role: "admin"), build(:organisation), :can_assign)
    end

    should "forbid for super organisation admins" do
      super_org_admin = create(:super_org_admin)
      admins_organisation = super_org_admin.organisation
      child_organisation = create(:organisation, parent_id: admins_organisation.id)

      # can't assign some random org
      assert forbid?(super_org_admin, build(:organisation), :can_assign)
      # can't assign the org they are an admin for
      assert forbid?(super_org_admin, admins_organisation, :can_assign)
      # can't assign an org that is in the subtree of the one they are an admin for
      assert forbid?(super_org_admin, child_organisation, :can_assign)
    end

    should "forbid for organisation admins" do
      organisation_admin = create(:organisation_admin)
      admins_organisation = organisation_admin.organisation
      child_organisation = create(:organisation, parent_id: admins_organisation.id)

      # can't assign some random org
      assert forbid?(organisation_admin, build(:organisation), :can_assign)
      # can't assign the org they are an admin for
      assert forbid?(organisation_admin, admins_organisation, :can_assign)
      # can't assign an org that is in the subtree of the one they are an admin for
      assert forbid?(organisation_admin, child_organisation, :can_assign)
    end
  end
end
