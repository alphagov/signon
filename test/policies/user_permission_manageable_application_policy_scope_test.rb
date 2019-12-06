require "test_helper"

class UserPermissionManageableApplicationPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @app_one = create(:application, name: "App one")
    @app_two = create(:application, name: "App two")
    @app_three = create(:application, name: "App three")
    @app_four = create(:application, name: "App four")

    @app_one_signin_permission = @app_one.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_two_signin_permission = @app_two.signin_permission.tap { |s| s.update(delegatable: false) }
    @app_three_signin_permission = @app_three.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_four_signin_permission = @app_four.signin_permission.tap { |s| s.update(delegatable: false) }
  end

  context "resolve" do
    should "include all application for superadmins" do
      user = create(:superadmin_user)
      resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      assert_includes resolved_scope, @app_one
      assert_includes resolved_scope, @app_two
      assert_includes resolved_scope, @app_three
      assert_includes resolved_scope, @app_four
    end

    should "include all application for admins" do
      user = create(:admin_user)
      resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      assert_includes resolved_scope, @app_one
      assert_includes resolved_scope, @app_two
      assert_includes resolved_scope, @app_three
      assert_includes resolved_scope, @app_four
    end

    context "super organisation admins" do
      setup do
        user = create(:super_org_admin).tap do |u|
          u.grant_application_permission(@app_one, "signin")
          u.grant_application_permission(@app_two, "signin")
        end

        @resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      end

      should "include applications with delegatable signin that the super organisation admin has access to" do
        assert_includes @resolved_scope, @app_one
      end

      should "not include applications without delegatable signin that the super organisation admin does has access to" do
        assert_not_includes @resolved_scope, @app_two
      end

      should "not include applications that the super organisation admin does not have access to" do
        assert_not_includes @resolved_scope, @app_three
        assert_not_includes @resolved_scope, @app_four
      end
    end

    context "for organisation admins" do
      setup do
        user = create(:organisation_admin).tap do |u|
          u.grant_application_permission(@app_one, "signin")
          u.grant_application_permission(@app_two, "signin")
        end

        @resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      end

      should "include applications with delegatable signin that the organisation admin has access to" do
        assert_includes @resolved_scope, @app_one
      end

      should "not include applications without delegatable signin that the organisation admin does has access to" do
        assert_not_includes @resolved_scope, @app_two
      end

      should "not include applications that the organisation admin does not have access to" do
        assert_not_includes @resolved_scope, @app_three
        assert_not_includes @resolved_scope, @app_four
      end
    end

    should "be empty for normal users" do
      user = create(:user)
      resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      assert_empty resolved_scope
    end
  end
end
