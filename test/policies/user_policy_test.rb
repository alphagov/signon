require "test_helper"
require "support/policy_helpers"

class UserPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  setup do
    @parent_organisation = create :organisation
    @child_organisation = create(:organisation, parent: @parent_organisation)
    @super_org_admin = create(:super_org_admin, organisation: @parent_organisation)
    @organisation_admin = create(:organisation_admin, organisation: @parent_organisation)
  end

  primary_management_actions = %i[new assign_organisations]
  user_management_actions = %i[edit create update unlock suspension cancel_email_change resend_email_change event_logs]
  self_management_actions = %i[edit_email_or_password update_email update_password cancel_email_change resend_email_change]
  superadmin_actions = %i[assign_role flag_2sv reset_2sv]

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
        assert permit?(user, build(:organisation_admin), permission)
        assert permit?(user, build(:super_org_admin), permission)
        assert permit?(user, build(:admin_user), permission)
        assert permit?(user, build(:superadmin_user), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "allow for #{permission}" do
        assert permit?(create(:superadmin_user), User, permission)
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
        assert permit?(user, build(:organisation_admin), permission)
        assert permit?(user, build(:super_org_admin), permission)
        assert permit?(user, build(:admin_user), permission)
        assert forbid?(user, build(:superadmin_user), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:admin_user), User, permission)
      end
    end
  end

  context "super organisation admins" do
    should "allow for index" do
      assert permit?(build(:super_org_admin), User, :index)
    end

    should "not allow for create" do
      assert forbid?(build(:super_org_admin), User, :create)
    end

    primary_management_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(build(:super_org_admin), User, permission)
      end
    end

    super_org_admin_actions.each do |permission|
      should "allow for #{permission} and users of similar permissions or below from within their own organisation" do
        assert permit?(@super_org_admin, build(:user_in_organisation, organisation: @super_org_admin.organisation), permission)
        assert permit?(@super_org_admin, build(:organisation_admin, organisation: @super_org_admin.organisation), permission)
        assert permit?(@super_org_admin, build(:super_org_admin, organisation: @super_org_admin.organisation), permission)

        assert forbid?(@super_org_admin, build(:superadmin_user), permission)
        assert forbid?(@super_org_admin, build(:admin_user), permission)
      end

      should "allow for #{permission} and users of similar permissions or below from within their own organisation's subtree" do
        assert permit?(@super_org_admin, build(:user_in_organisation, organisation: @child_organisation), permission)
        assert permit?(@super_org_admin, build(:organisation_admin, organisation: @child_organisation), permission)
        assert permit?(@super_org_admin, build(:super_org_admin, organisation: @child_organisation), permission)

        assert forbid?(@super_org_admin, build(:superadmin_user, organisation: @child_organisation), permission)
        assert forbid?(@super_org_admin, build(:admin_user, organisation: @child_organisation), permission)
      end

      should "not allow for #{permission} and users from other organisations" do
        assert forbid?(@super_org_admin, build(:organisation_admin), permission)
        assert forbid?(@super_org_admin, build(:super_org_admin), permission)
        assert forbid?(@super_org_admin, build(:admin_user), permission)
        assert forbid?(@super_org_admin, build(:superadmin_user), permission)
        assert forbid?(@super_org_admin, build(:user_in_organisation), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:super_org_admin), User, permission)
      end
    end
  end

  context "organisation admins" do
    should "allow for index" do
      assert permit?(build(:organisation_admin), User, :index)
    end

    should "not allow for create" do
      assert forbid?(build(:organisation_admin), User, :create)
    end

    primary_management_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(build(:organisation_admin), User, permission)
      end
    end

    org_admin_actions.each do |permission|
      should "allow for #{permission} and users of similar permissions or below from within their own organisation" do
        assert permit?(@organisation_admin, build(:user_in_organisation, organisation: @organisation_admin.organisation), permission)
        assert permit?(@organisation_admin, build(:organisation_admin, organisation: @organisation_admin.organisation), permission)

        assert forbid?(@organisation_admin, build(:super_org_admin, organisation: @organisation_admin.organisation), permission)
        assert forbid?(@organisation_admin, build(:superadmin_user), permission)
        assert forbid?(@organisation_admin, build(:admin_user), permission)
      end

      should "allow for #{permission} and users of similar permissions or below from within their own organisation's subtree" do
        assert forbid?(@organisation_admin, build(:user_in_organisation, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:organisation_admin, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:super_org_admin, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:superadmin_user, organisation: @child_organisation), permission)
        assert forbid?(@organisation_admin, build(:admin_user, organisation: @child_organisation), permission)
      end

      should "not allow for #{permission} and users from other organisations" do
        assert forbid?(@organisation_admin, build(:organisation_admin), permission)
        assert forbid?(@organisation_admin, build(:super_org_admin), permission)
        assert forbid?(@organisation_admin, build(:admin_user), permission)
        assert forbid?(@organisation_admin, build(:superadmin_user), permission)
        assert forbid?(@organisation_admin, build(:user_in_organisation), permission)
      end
    end

    superadmin_actions.each do |permission|
      should "not allow for #{permission}" do
        assert forbid?(create(:organisation_admin), User, permission)
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
        assert forbid?(user, build(:organisation_admin), permission)
        assert forbid?(user, build(:super_org_admin), permission)
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

    admin_actions.each do |permission|
      should "not allow for #{permission} accessing their own record" do
        user = create(:user)
        assert forbid?(user, user, permission)
      end
    end
  end
end
