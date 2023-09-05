require "test_helper"
require "support/policy_helpers"

class UserPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  setup do
    @parent_organisation = create :organisation
    @child_organisation = create(:organisation, parent: @parent_organisation)
    @super_org_admin = create(:super_organisation_admin_user, organisation: @parent_organisation)
    @organisation_admin = create(:organisation_admin_user, organisation: @parent_organisation)
    @gds = create(:organisation, name: "Government Digital Services", content_id: Organisation::GDS_ORG_CONTENT_ID)
  end

  primary_management_actions = %i[new assign_organisations]
  user_management_actions = %i[edit create update unlock suspension cancel_email_change resend_email_change event_logs reset_2sv mandate_2sv]
  self_management_actions = %i[edit_email_or_password update_email update_password cancel_email_change resend_email_change]
  superadmin_actions = %i[assign_role]
  two_step_verification_exemption_actions = %i[exempt_from_two_step_verification]

  org_admin_actions = user_management_actions - %i[create]
  super_org_admin_actions = user_management_actions - %i[create]
  admin_actions = user_management_actions - self_management_actions

  context "superadmins" do
    should "allow for index" do
      assert permit?(build(:superadmin_user), User, :index)
    end

    primary_management_actions.each do |permission|
      should "allow for #{permission}" do
        assert permit?(build(:superadmin_user), User, permission)
      end
    end

    user_management_actions.each do |permission|
      should "allow for #{permission} and equal or fewer privileges" do
        user = create(:superadmin_user)

        assert permit?(user, build(:user), permission)
        assert permit?(user, build(:organisation_admin_user), permission)
        assert permit?(user, build(:super_organisation_admin_user), permission)
        assert permit?(user, build(:admin_user), permission)
        assert permit?(user, build(:superadmin_user), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "allow for #{permission}" do
        assert permit?(create(:superadmin_user), User, permission)
      end
    end

    two_step_verification_exemption_actions.each do |permission|
      should "allow for #{permission} if the superadmin belongs to gds and user being edited is a normal user" do
        user = create(:user)
        assert permit?(create(:superadmin_user, organisation: @gds), user, permission)
      end

      should "not allow for #{permission} if the superadmin does not belong to gds and user being edited is a normal user" do
        user = create(:user)
        assert forbid?(create(:superadmin_user, organisation: @organisation), user, permission)
      end

      should "not allow for #{permission} if the superadmin belongs to gds and user being edited is an admin user" do
        user = create(:superadmin_user)
        assert forbid?(create(:superadmin_user, organisation: @gds), user, permission)
      end

      should "not allow for #{permission} if the user is an api user" do
        user = create(:api_user)
        assert forbid?(create(:superadmin_user, organisation: @gds), user, permission)
      end
    end
  end

  context "admins" do
    should "allow for index" do
      assert permit?(build(:admin_user), User, :index)
    end

    primary_management_actions.each do |permission|
      should "allow for #{permission}" do
        assert permit?(build(:admin_user), User, permission)
      end
    end

    user_management_actions.each do |permission|
      should "allow for #{permission} and equal or fewer privileges" do
        user = create(:admin_user)

        assert permit?(user, build(:user), permission)
        assert permit?(user, build(:organisation_admin_user), permission)
        assert permit?(user, build(:super_organisation_admin_user), permission)
        assert permit?(user, build(:admin_user), permission)
        assert forbid?(user, build(:superadmin_user), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:admin_user), User, permission)
      end
    end

    two_step_verification_exemption_actions.each do |permission|
      should "allow for #{permission} if the admin belongs to gds and user being edited is a normal user" do
        user = create(:user)
        assert permit?(create(:admin_user, organisation: @gds), user, permission)
      end

      should "not allow for #{permission} if the admin does not belong to gds and user being edited is a normal user" do
        user = create(:user)
        assert forbid?(create(:admin_user, organisation: @organisation), user, permission)
      end

      should "not allow for #{permission} if the admin belongs to gds and user being edited is an admin user" do
        user = create(:admin_user)
        assert forbid?(create(:admin_user, organisation: @gds), user, permission)
      end
    end
  end

  context "super organisation admins" do
    should "allow for index" do
      assert permit?(build(:super_organisation_admin_user), User, :index)
    end

    should "not allow for create" do
      assert forbid?(build(:super_organisation_admin_user), User, :create)
    end

    primary_management_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(build(:super_organisation_admin_user), User, permission)
      end
    end

    super_org_admin_actions.each do |permission|
      should "allow for #{permission} and users of similar permissions or below from within their own organisation" do
        assert permit?(@super_org_admin, build(:user_in_organisation, organisation: @super_org_admin.organisation), permission)
        assert permit?(@super_org_admin, build(:organisation_admin_user, organisation: @super_org_admin.organisation), permission)
        assert permit?(@super_org_admin, build(:super_organisation_admin_user, organisation: @super_org_admin.organisation), permission)

        assert forbid?(@super_org_admin, build(:superadmin_user), permission)
        assert forbid?(@super_org_admin, build(:admin_user), permission)
      end

      should "allow for #{permission} and users of similar permissions or below from within their own organisation's subtree" do
        assert permit?(@super_org_admin, build(:user_in_organisation, organisation: @child_organisation), permission)
        assert permit?(@super_org_admin, build(:organisation_admin_user, organisation: @child_organisation), permission)
        assert permit?(@super_org_admin, build(:super_organisation_admin_user, organisation: @child_organisation), permission)

        assert forbid?(@super_org_admin, build(:superadmin_user, organisation: @child_organisation), permission)
        assert forbid?(@super_org_admin, build(:admin_user, organisation: @child_organisation), permission)
      end

      should "not allow for #{permission} and users from other organisations" do
        assert forbid?(@super_org_admin, build(:organisation_admin_user), permission)
        assert forbid?(@super_org_admin, build(:super_organisation_admin_user), permission)
        assert forbid?(@super_org_admin, build(:admin_user), permission)
        assert forbid?(@super_org_admin, build(:superadmin_user), permission)
        assert forbid?(@super_org_admin, build(:user_in_organisation), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:super_organisation_admin_user), User, permission)
      end
    end

    two_step_verification_exemption_actions.each do |permission|
      should "not allow for #{permission}" do
        user = create(:super_organisation_admin_user)
        assert forbid?(create(:super_organisation_admin_user), user, permission)
      end
    end
  end

  context "organisation admins" do
    should "allow for index" do
      assert permit?(build(:organisation_admin_user), User, :index)
    end

    should "not allow for create" do
      assert forbid?(build(:organisation_admin_user), User, :create)
    end

    primary_management_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(build(:organisation_admin_user), User, permission)
      end
    end

    org_admin_actions.each do |permission|
      should "allow for #{permission} and users of similar permissions or below from within their own organisation" do
        assert permit?(@organisation_admin, build(:user_in_organisation, organisation: @organisation_admin.organisation), permission)
        assert permit?(@organisation_admin, build(:organisation_admin_user, organisation: @organisation_admin.organisation), permission)

        assert forbid?(@organisation_admin, build(:super_organisation_admin_user, organisation: @organisation_admin.organisation), permission)
        assert forbid?(@organisation_admin, build(:superadmin_user), permission)
        assert forbid?(@organisation_admin, build(:admin_user), permission)
      end

      should "allow for #{permission} and users of similar permissions or below from within their own organisation's subtree" do
        assert forbid?(@organisation_admin, build(:user_in_organisation, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:organisation_admin_user, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:super_organisation_admin_user, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:superadmin_user, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:admin_user, organisation: @child_organisation), permission)
      end

      should "not allow for #{permission} and users from other organisations" do
        assert forbid?(@organisation_admin, build(:organisation_admin_user), permission)
        assert forbid?(@organisation_admin, build(:super_organisation_admin_user), permission)
        assert forbid?(@organisation_admin, build(:admin_user), permission)
        assert forbid?(@organisation_admin, build(:superadmin_user), permission)
        assert forbid?(@organisation_admin, build(:user_in_organisation), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:organisation_admin_user), User, permission)
      end
    end

    two_step_verification_exemption_actions.each do |permission|
      should "not allow for #{permission}" do
        user = create(:organisation_admin_user)
        assert forbid?(create(:organisation_admin_user), user, permission)
      end
    end
  end

  context "normal users" do
    should "not allow for index" do
      assert forbid?(build(:user), User, :index)
    end

    primary_management_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(build(:user), User, permission)
      end
    end

    user_management_actions.each do |permission|
      should "not allow for #{permission} and equal or fewer privileges" do
        user = create(:user)
        assert forbid?(user, build(:user), permission)
        assert forbid?(user, build(:organisation_admin_user), permission)
        assert forbid?(user, build(:super_organisation_admin_user), permission)
        assert forbid?(user, build(:admin_user), permission)
        assert forbid?(user, build(:superadmin_user), permission)
      end
    end

    self_management_actions.each do |permission|
      should "allow for #{permission} accessing their own record" do
        user = create(:user)
        assert permit?(user, user, permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:user), User, permission)
      end
    end

    two_step_verification_exemption_actions.each do |permission|
      should "not allow for #{permission}" do
        user = create(:user)
        assert forbid?(create(:user), user, permission)
      end
    end

    admin_actions.each do |permission|
      should "not allow for #{permission} accessing their own record" do
        user = create(:user)
        assert forbid?(user, user, permission)
      end
    end
  end
end
