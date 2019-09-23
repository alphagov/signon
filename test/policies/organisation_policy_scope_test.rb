require "test_helper"

class OrganisationPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @parent_organisation = create(:organisation)
    @child_organisation_one = create(:organisation, parent: @parent_organisation)
    @child_organisation_two = create(:organisation, parent: @parent_organisation)
    @grandchild_organisation_one = create(:organisation, parent: @child_organisation_one)
    @second_parent_organisation = create(:organisation)
    @child_second_organisation = create(:organisation, parent: @second_parent_organisation)
  end

  context "resolve" do
    should "include all organisations for super admins" do
      user = create(:superadmin_user)
      resolved_scope = OrganisationPolicy::Scope.new(user, Organisation.all).resolve
      assert_includes resolved_scope, @parent_organisation
      assert_includes resolved_scope, @child_organisation_one
      assert_includes resolved_scope, @child_organisation_two
      assert_includes resolved_scope, @grandchild_organisation_one
      assert_includes resolved_scope, @second_parent_organisation
      assert_includes resolved_scope, @child_second_organisation
    end

    should "include all organisations for admins" do
      user = create(:admin_user)
      resolved_scope = OrganisationPolicy::Scope.new(user, Organisation.all).resolve
      assert_includes resolved_scope, @parent_organisation
      assert_includes resolved_scope, @child_organisation_one
      assert_includes resolved_scope, @child_organisation_two
      assert_includes resolved_scope, @grandchild_organisation_one
      assert_includes resolved_scope, @second_parent_organisation
      assert_includes resolved_scope, @child_second_organisation
    end

    should "is empty for super organisation admins" do
      user = create(:super_org_admin, organisation: @parent_organisation)
      resolved_scope = OrganisationPolicy::Scope.new(user, Organisation.all).resolve
      assert_empty resolved_scope
    end

    should "is empty for organisation admins" do
      user = create(:organisation_admin, organisation: @parent_organisation)
      resolved_scope = OrganisationPolicy::Scope.new(user, Organisation.all).resolve
      assert_empty resolved_scope
    end

    should "is empty for normal users" do
      user = create(:user)
      resolved_scope = OrganisationPolicy::Scope.new(user, Organisation.all).resolve
      assert_empty resolved_scope
    end
  end
end
