require "test_helper"

class UserPermissionManageableApplicationPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @app_one = create(:application, name: "App one")
    @app_two = create(:application, name: "App two")
    @app_three = create(:application, name: "App three")
    @app_four = create(:application, name: "App four")
    @retired_app = create(:application, name: "Retired app", retired: true)
    @api_only_app = create(:application, name: "API-only app", api_only: true)

    @app_one_signin_permission = @app_one.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_two_signin_permission = @app_two.signin_permission.tap { |s| s.update(delegatable: false) }
    @app_three_signin_permission = @app_three.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_four_signin_permission = @app_four.signin_permission.tap { |s| s.update(delegatable: false) }
    @retired_app_signin_permission = @retired_app.signin_permission.tap { |s| s.update(delegatable: true) }
    @api_only_app_signin_permission = @api_only_app.signin_permission.tap { |s| s.update(delegatable: true) }
  end

  context "resolve" do
    should "include all application for superadmins except retired & API-only apps" do
      user = create(:superadmin_user)
      resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      assert_includes resolved_scope, @app_one
      assert_includes resolved_scope, @app_two
      assert_includes resolved_scope, @app_three
      assert_includes resolved_scope, @app_four
      assert_not_includes resolved_scope, @retired_app
      assert_not_includes resolved_scope, @api_only_app
    end

    should "include all application for admins except retired & API-only apps" do
      user = create(:admin_user)
      resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      assert_includes resolved_scope, @app_one
      assert_includes resolved_scope, @app_two
      assert_includes resolved_scope, @app_three
      assert_includes resolved_scope, @app_four
      assert_not_includes resolved_scope, @retired_app
      assert_not_includes resolved_scope, @api_only_app
    end

    context "super organisation admins" do
      setup do
        user = create(:super_organisation_admin_user).tap do |u|
          u.grant_application_signin_permission(@app_one)
          u.grant_application_signin_permission(@app_two)
        end

        @resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      end

      should "include non-retired, non-API-only applications with delegatable signin that the super organisation admin has access to" do
        assert_includes @resolved_scope, @app_one
        assert_not_includes @resolved_scope, @retired_app
        assert_not_includes @resolved_scope, @api_only_app
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
        user = create(:organisation_admin_user).tap do |u|
          u.grant_application_signin_permission(@app_one)
          u.grant_application_signin_permission(@app_two)
        end

        @resolved_scope = UserPermissionManageableApplicationPolicy::Scope.new(user).resolve
      end

      should "include non-retired, non-API-only applications with delegatable signin that the organisation admin has access to" do
        assert_includes @resolved_scope, @app_one
        assert_not_includes @resolved_scope, @retired_app
        assert_not_includes @resolved_scope, @api_only_app
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
