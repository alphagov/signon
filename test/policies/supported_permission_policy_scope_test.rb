require "test_helper"

class SupportedPermissionPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @app_one = create(:application, name: "App one")
    @app_two = create(:application, name: "App two")
    @app_three = create(:application, name: "App three")
    @app_four = create(:application, name: "App four")

    @app_one_signin_permission = @app_one.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_two_signin_permission = @app_two.signin_permission.tap { |s| s.update(delegatable: false) }
    @app_three_signin_permission = @app_three.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_four_signin_permission = @app_four.signin_permission.tap { |s| s.update(delegatable: false) }

    @app_one_hat_permission = create(:non_delegatable_supported_permission, application: @app_one, name: "hat")
    @app_one_cat_permission = create(:delegatable_supported_permission, application: @app_one, name: "cat")

    @app_two_rat_permission = create(:non_delegatable_supported_permission, application: @app_two, name: "rat")
    @app_two_bat_permission = create(:delegatable_supported_permission, application: @app_two, name: "bat")

    @app_three_fat_permission = create(:non_delegatable_supported_permission, application: @app_three, name: "fat")
    @app_three_vat_permission = create(:delegatable_supported_permission, application: @app_three, name: "vat")

    @app_four_pat_permission = create(:non_delegatable_supported_permission, application: @app_three, name: "pat")
    @app_four_sat_permission = create(:delegatable_supported_permission, application: @app_three, name: "sat")
  end

  context "resolve" do
    should "include all permissions for superadmins" do
      user = create(:superadmin_user)
      resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve

      assert_includes resolved_scope, @app_one_signin_permission
      assert_includes resolved_scope, @app_one_hat_permission
      assert_includes resolved_scope, @app_one_cat_permission

      assert_includes resolved_scope, @app_two_signin_permission
      assert_includes resolved_scope, @app_two_rat_permission
      assert_includes resolved_scope, @app_two_bat_permission

      assert_includes resolved_scope, @app_three_signin_permission
      assert_includes resolved_scope, @app_three_fat_permission
      assert_includes resolved_scope, @app_three_vat_permission

      assert_includes resolved_scope, @app_four_signin_permission
      assert_includes resolved_scope, @app_four_pat_permission
      assert_includes resolved_scope, @app_four_sat_permission
    end

    should "include all permissions for admins" do
      user = create(:admin_user)
      resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve

      assert_includes resolved_scope, @app_one_signin_permission
      assert_includes resolved_scope, @app_one_hat_permission
      assert_includes resolved_scope, @app_one_cat_permission

      assert_includes resolved_scope, @app_two_signin_permission
      assert_includes resolved_scope, @app_two_rat_permission
      assert_includes resolved_scope, @app_two_bat_permission

      assert_includes resolved_scope, @app_three_signin_permission
      assert_includes resolved_scope, @app_three_fat_permission
      assert_includes resolved_scope, @app_three_vat_permission

      assert_includes resolved_scope, @app_four_signin_permission
      assert_includes resolved_scope, @app_four_pat_permission
      assert_includes resolved_scope, @app_four_sat_permission
    end

    context "super organisation admins" do
      setup do
        user = create(:super_org_admin).tap do |u|
          u.grant_application_permission(@app_one, "signin")
          u.grant_application_permission(@app_two, "signin")
        end

        @resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve
      end

      should "contain all permissions for apps with delegatable signin permission that the super organisation admin has access to" do
        assert_includes @resolved_scope, @app_one_signin_permission
        assert_includes @resolved_scope, @app_one_cat_permission
        assert_includes @resolved_scope, @app_one_hat_permission
      end

      should "not contain any permissions for apps with non-delegatbale signin permission the super organisation admin has access to" do
        assert_not_includes @resolved_scope, @app_two_signin_permission
        assert_not_includes @resolved_scope, @app_two_rat_permission
        assert_not_includes @resolved_scope, @app_two_bat_permission
      end

      should "not contain any permissions for apps the super organisation admin does not have access to" do
        assert_not_includes @resolved_scope, @app_three_signin_permission
        assert_not_includes @resolved_scope, @app_three_fat_permission
        assert_not_includes @resolved_scope, @app_three_vat_permission

        assert_not_includes @resolved_scope, @app_four_signin_permission
        assert_not_includes @resolved_scope, @app_four_pat_permission
        assert_not_includes @resolved_scope, @app_four_sat_permission
      end
    end

    context "organisation admins" do
      setup do
        user = create(:organisation_admin).tap do |u|
          u.grant_application_permission(@app_one, "signin")
          u.grant_application_permission(@app_two, "signin")
        end

        @resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve
      end

      should "contain all permissions for apps with delegatable signin permission that the organisation admin has access to" do
        assert_includes @resolved_scope, @app_one_signin_permission
        assert_includes @resolved_scope, @app_one_cat_permission
        assert_includes @resolved_scope, @app_one_hat_permission
      end

      should "not contain any permissions for apps with non-delegatbale signin permission the organisation admin has access to" do
        assert_not_includes @resolved_scope, @app_two_signin_permission
        assert_not_includes @resolved_scope, @app_two_rat_permission
        assert_not_includes @resolved_scope, @app_two_bat_permission
      end

      should "not contain any permissions for apps the organisation admin does not have access to" do
        assert_not_includes @resolved_scope, @app_three_signin_permission
        assert_not_includes @resolved_scope, @app_three_fat_permission
        assert_not_includes @resolved_scope, @app_three_vat_permission

        assert_not_includes @resolved_scope, @app_four_signin_permission
        assert_not_includes @resolved_scope, @app_four_pat_permission
        assert_not_includes @resolved_scope, @app_four_sat_permission
      end
    end

    should "be empty for normal users" do
      user = create(:user)
      resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve
      assert_empty resolved_scope
    end
  end
end
