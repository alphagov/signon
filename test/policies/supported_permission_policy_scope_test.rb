require "test_helper"

class SupportedPermissionPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @app_one = create(:application, name: "App one")
    @app_two = create(:application, name: "App two")
    @app_three = create(:application, name: "App three")
    @app_four = create(:application, name: "App four")
    @api_only_app = create(:application, name: "API-only app", api_only: true)

    @app_one_signin_permission = @app_one.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_two_signin_permission = @app_two.signin_permission.tap { |s| s.update(delegatable: false) }
    @app_three_signin_permission = @app_three.signin_permission.tap { |s| s.update(delegatable: true) }
    @app_four_signin_permission = @app_four.signin_permission.tap { |s| s.update(delegatable: false) }
    @api_only_app_signin_permission = @api_only_app.signin_permission.tap { |s| s.update(delegatable: true) }

    @app_one_hat_permission = create(:non_delegatable_supported_permission, application: @app_one, name: "hat")
    @app_one_cat_permission = create(:delegatable_supported_permission, application: @app_one, name: "cat")

    @app_two_rat_permission = create(:non_delegatable_supported_permission, application: @app_two, name: "rat")
    @app_two_bat_permission = create(:delegatable_supported_permission, application: @app_two, name: "bat")

    @app_three_fat_permission = create(:non_delegatable_supported_permission, application: @app_three, name: "fat")
    @app_three_vat_permission = create(:delegatable_supported_permission, application: @app_three, name: "vat")

    @app_four_pat_permission = create(:non_delegatable_supported_permission, application: @app_three, name: "pat")
    @app_four_sat_permission = create(:delegatable_supported_permission, application: @app_three, name: "sat")

    @api_only_app_nat_permission = create(:non_delegatable_supported_permission, application: @api_only_app, name: "nat")
    @api_only_app_mat_permission = create(:delegatable_supported_permission, application: @api_only_app, name: "mat")
  end

  context "resolve" do
    %w[superadmin admin].each do |govuk_admin_role|
      should "include all permissions for #{govuk_admin_role}s" do
        user = create(:"#{govuk_admin_role}_user")
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

        assert_includes resolved_scope, @api_only_app_signin_permission
        assert_includes resolved_scope, @api_only_app_nat_permission
        assert_includes resolved_scope, @api_only_app_mat_permission
      end
    end

    ["super organisation admin", "organisation admin"].each do |publishing_manager_role|
      context "#{publishing_manager_role}s" do
        setup do
          user = create(:"#{publishing_manager_role.tr(' ', '_')}_user").tap do |u|
            u.grant_application_signin_permission(@app_one)
            u.grant_application_signin_permission(@app_two)
            u.grant_application_signin_permission(@api_only_app)
          end

          @resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve
        end

        should "contain all permissions for non-API-only apps with delegatable signin permission that the #{publishing_manager_role} has access to" do
          assert_includes @resolved_scope, @app_one_signin_permission
          assert_includes @resolved_scope, @app_one_cat_permission
          assert_includes @resolved_scope, @app_one_hat_permission
        end

        should "not contain any permissions for apps with non-delegatable signin permission the #{publishing_manager_role} has access to" do
          assert_not_includes @resolved_scope, @app_two_signin_permission
          assert_not_includes @resolved_scope, @app_two_rat_permission
          assert_not_includes @resolved_scope, @app_two_bat_permission
        end

        should "not contain any permissions for apps the #{publishing_manager_role} does not have access to" do
          assert_not_includes @resolved_scope, @app_three_signin_permission
          assert_not_includes @resolved_scope, @app_three_fat_permission
          assert_not_includes @resolved_scope, @app_three_vat_permission

          assert_not_includes @resolved_scope, @app_four_signin_permission
          assert_not_includes @resolved_scope, @app_four_pat_permission
          assert_not_includes @resolved_scope, @app_four_sat_permission
        end

        should "not contain any permissions for API-only apps" do
          assert_not_includes @resolved_scope, @api_only_app_signin_permission
          assert_not_includes @resolved_scope, @api_only_app_nat_permission
          assert_not_includes @resolved_scope, @api_only_app_mat_permission
        end
      end
    end

    should "be empty for normal users" do
      user = create(:user)
      resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve
      assert_empty resolved_scope
    end
  end
end
