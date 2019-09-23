require "test_helper"

class UserPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @parent_organisation = create(:organisation)
    @child_organisation = create(:organisation, parent: @parent_organisation)
    @other_organisation = create(:organisation)

    @super_admin_in_org = create(:superadmin_user, organisation: @parent_organisation)
    @admin_in_org = create(:admin_user, organisation: @parent_organisation)
    @super_org_admin_in_org = create(:super_org_admin, organisation: @parent_organisation)
    @org_admin_in_org = create(:organisation_admin, organisation: @parent_organisation)
    @normal_user_in_org = create(:user_in_organisation, organisation: @parent_organisation)

    @super_admin_in_child_org = create(:superadmin_user, organisation: @child_organisation)
    @admin_in_child_org = create(:admin_user, organisation: @child_organisation)
    @super_org_admin_in_child_org = create(:super_org_admin, organisation: @child_organisation)
    @org_admin_in_child_org = create(:organisation_admin, organisation: @child_organisation)
    @normal_user_in_child_org = create(:user_in_organisation, organisation: @child_organisation)

    @super_admin_in_other_org = create(:superadmin_user, organisation: @other_organisation)
    @admin_in_other_org = create(:admin_user, organisation: @other_organisation)
    @super_org_admin_in_other_org = create(:super_org_admin, organisation: @other_organisation)
    @org_admin_in_other_org = create(:organisation_admin, organisation: @other_organisation)
    @normal_user_in_other_org = create(:user_in_organisation, organisation: @other_organisation)

    @api_user = create(:api_user)
  end

  context "super admins" do
    should "include all web users" do
      user = create(:superadmin_user)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      assert_includes resolved_scope, @super_admin_in_org
      assert_includes resolved_scope, @admin_in_org
      assert_includes resolved_scope, @super_org_admin_in_org
      assert_includes resolved_scope, @org_admin_in_org
      assert_includes resolved_scope, @normal_user_in_org

      assert_includes resolved_scope, @super_admin_in_child_org
      assert_includes resolved_scope, @admin_in_child_org
      assert_includes resolved_scope, @super_org_admin_in_child_org
      assert_includes resolved_scope, @org_admin_in_child_org
      assert_includes resolved_scope, @normal_user_in_child_org

      assert_includes resolved_scope, @super_admin_in_other_org
      assert_includes resolved_scope, @admin_in_other_org
      assert_includes resolved_scope, @super_org_admin_in_other_org
      assert_includes resolved_scope, @org_admin_in_other_org
      assert_includes resolved_scope, @normal_user_in_other_org
    end

    should "not include api users" do
      user = create(:superadmin_user)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve
      refute_includes resolved_scope, @api_user
    end
  end

  context "admins" do
    should "includes all web users of similar permissions or below belonging to their organisation" do
      user = create(:admin_user)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_org
      assert_includes resolved_scope, @admin_in_org
      assert_includes resolved_scope, @super_org_admin_in_org
      assert_includes resolved_scope, @org_admin_in_org
      assert_includes resolved_scope, @normal_user_in_org
    end

    should "includes all web users of similar permissions or below belonging to a child organisation" do
      user = create(:admin_user)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_child_org
      assert_includes resolved_scope, @admin_in_child_org
      assert_includes resolved_scope, @super_org_admin_in_child_org
      assert_includes resolved_scope, @org_admin_in_child_org
      assert_includes resolved_scope, @normal_user_in_child_org
    end

    should "includes all web users of similar permissions or below belonging to another organisation" do
      user = create(:admin_user)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_other_org
      assert_includes resolved_scope, @admin_in_other_org
      assert_includes resolved_scope, @super_org_admin_in_other_org
      assert_includes resolved_scope, @org_admin_in_other_org
      assert_includes resolved_scope, @normal_user_in_other_org
    end

    should "does not include api users" do
      user = create(:admin_user)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve
      refute_includes resolved_scope, @api_user
    end
  end

  context "super organisation admins" do
    should "includes users of similar permission or below belonging to their organisation" do
      user = create(:super_org_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_org
      refute_includes resolved_scope, @admin_in_org
      assert_includes resolved_scope, @super_org_admin_in_org
      assert_includes resolved_scope, @org_admin_in_org
      assert_includes resolved_scope, @normal_user_in_org
    end

    should "includes users of similar permission or below belonging to a child organisation" do
      user = create(:super_org_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_child_org
      refute_includes resolved_scope, @admin_in_child_org
      assert_includes resolved_scope, @super_org_admin_in_child_org
      assert_includes resolved_scope, @org_admin_in_child_org
      assert_includes resolved_scope, @normal_user_in_child_org
    end

    should "does not include users of similar permission or below belonging to another organisation" do
      user = create(:super_org_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_other_org
      refute_includes resolved_scope, @admin_in_other_org
      refute_includes resolved_scope, @super_org_admin_in_other_org
      refute_includes resolved_scope, @org_admin_in_other_org
      refute_includes resolved_scope, @normal_user_in_other_org
    end

    should "does not include api users" do
      user = create(:super_org_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve
      refute_includes resolved_scope, @api_user
    end
  end

  context "organisation admins" do
    should "includes users of similar permission or below belonging to their organisation" do
      user = create(:organisation_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_org
      refute_includes resolved_scope, @admin_in_org
      refute_includes resolved_scope, @super_org_admin_in_org
      assert_includes resolved_scope, @org_admin_in_org
      assert_includes resolved_scope, @normal_user_in_org
    end

    should "does not include users of similar permission or below belonging to a child organisation" do
      user = create(:organisation_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_child_org
      refute_includes resolved_scope, @admin_in_child_org
      refute_includes resolved_scope, @super_org_admin_in_child_org
      refute_includes resolved_scope, @org_admin_in_child_org
      refute_includes resolved_scope, @normal_user_in_child_org
    end

    should "does not include users of similar permission or below belonging to another organisation" do
      user = create(:organisation_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve

      refute_includes resolved_scope, @super_admin_in_other_org
      refute_includes resolved_scope, @admin_in_other_org
      refute_includes resolved_scope, @super_org_admin_in_other_org
      refute_includes resolved_scope, @org_admin_in_other_org
      refute_includes resolved_scope, @normal_user_in_other_org
    end

    should "does not include api users" do
      user = create(:organisation_admin, organisation: @parent_organisation)
      resolved_scope = UserPolicy::Scope.new(user, User.all).resolve
      refute_includes resolved_scope, @api_user
    end
  end

  should "be empty for normal users" do
    user = create(:user)
    resolved_scope = UserPolicy::Scope.new(user, User.all).resolve
    assert_empty resolved_scope
  end
end
