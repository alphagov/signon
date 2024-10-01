require "test_helper"

class SupportedPermissionPolicyScopeTest < ActiveSupport::TestCase
  setup do
    @delegated_signin_app_one = create(:application, with_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])
    @delegated_signin_app_two = create(:application, with_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])
    @non_delegated_signin_app_one = create(:application, with_non_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])
    @non_delegated_signin_app_two = create(:application, with_non_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])
    @api_only_app = create(:application, name: "API-only app", api_only: true, with_delegated_supported_permissions: [SupportedPermission::SIGNIN_NAME])

    @delegated_signin_app_one_delegated_permission = create(:delegated_supported_permission, application: @delegated_signin_app_one)
    @delegated_signin_app_one_non_delegated_permission = create(:non_delegated_supported_permission, application: @delegated_signin_app_one)

    @delegated_signin_app_two_delegated_permission = create(:delegated_supported_permission, application: @delegated_signin_app_two)
    @delegated_signin_app_two_non_delegated_permission = create(:non_delegated_supported_permission, application: @delegated_signin_app_two)

    @non_delegated_signin_app_one_delegated_permission = create(:delegated_supported_permission, application: @non_delegated_signin_app_one)
    @non_delegated_signin_app_one_non_delegated_permission = create(:non_delegated_supported_permission, application: @non_delegated_signin_app_one)

    @non_delegated_signin_app_two_delegated_permission = create(:delegated_supported_permission, application: @non_delegated_signin_app_two)
    @non_delegated_signin_app_two_non_delegated_permission = create(:non_delegated_supported_permission, application: @non_delegated_signin_app_two)

    @api_only_app_delegated_permission = create(:delegated_supported_permission, application: @api_only_app)
    @api_only_app_non_delegated_permission = create(:non_delegated_supported_permission, application: @api_only_app)
  end

  context "resolve" do
    %w[superadmin admin].each do |govuk_admin_role|
      should "include all permissions for #{govuk_admin_role}s" do
        user = create(:"#{govuk_admin_role}_user")
        resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve

        assert_includes resolved_scope, @delegated_signin_app_one.signin_permission
        assert_includes resolved_scope, @delegated_signin_app_one_delegated_permission
        assert_includes resolved_scope, @delegated_signin_app_one_non_delegated_permission

        assert_includes resolved_scope, @delegated_signin_app_two.signin_permission
        assert_includes resolved_scope, @delegated_signin_app_two_delegated_permission
        assert_includes resolved_scope, @delegated_signin_app_two_non_delegated_permission

        assert_includes resolved_scope, @non_delegated_signin_app_one.signin_permission
        assert_includes resolved_scope, @non_delegated_signin_app_one_delegated_permission
        assert_includes resolved_scope, @non_delegated_signin_app_one_non_delegated_permission

        assert_includes resolved_scope, @non_delegated_signin_app_two.signin_permission
        assert_includes resolved_scope, @non_delegated_signin_app_two_delegated_permission
        assert_includes resolved_scope, @non_delegated_signin_app_two_non_delegated_permission

        assert_includes resolved_scope, @api_only_app.signin_permission
        assert_includes resolved_scope, @api_only_app_delegated_permission
        assert_includes resolved_scope, @api_only_app_non_delegated_permission
      end
    end

    ["super organisation admin", "organisation admin"].each do |publishing_manager_role|
      context "#{publishing_manager_role}s" do
        setup do
          user = create(:"#{publishing_manager_role.tr(' ', '_')}_user").tap do |u|
            u.grant_application_signin_permission(@delegated_signin_app_one)
            u.grant_application_signin_permission(@non_delegated_signin_app_one)
            u.grant_application_signin_permission(@api_only_app)
          end

          @resolved_scope = SupportedPermissionPolicy::Scope.new(user, SupportedPermission.all).resolve
        end

        should "contain all delegated permissions for non-API-only apps that the #{publishing_manager_role} has access to" do
          assert_includes @resolved_scope, @delegated_signin_app_one.signin_permission
          assert_includes @resolved_scope, @delegated_signin_app_one_delegated_permission

          assert_includes @resolved_scope, @non_delegated_signin_app_one_delegated_permission
        end

        should "not contain any non-delegated permissions for non-API-only apps the #{publishing_manager_role} has access to" do
          assert_not_includes @resolved_scope, @delegated_signin_app_one_non_delegated_permission

          assert_not_includes @resolved_scope, @non_delegated_signin_app_one.signin_permission
          assert_not_includes @resolved_scope, @non_delegated_signin_app_one_non_delegated_permission
        end

        should "not contain any permissions for non-API-only apps the #{publishing_manager_role} does not have access to" do
          assert_not_includes @resolved_scope, @delegated_signin_app_two.signin_permission
          assert_not_includes @resolved_scope, @delegated_signin_app_two_delegated_permission
          assert_not_includes @resolved_scope, @delegated_signin_app_two_non_delegated_permission

          assert_not_includes @resolved_scope, @non_delegated_signin_app_two.signin_permission
          assert_not_includes @resolved_scope, @non_delegated_signin_app_two_delegated_permission
          assert_not_includes @resolved_scope, @non_delegated_signin_app_two_non_delegated_permission
        end

        should "not contain any permissions for API-only apps" do
          assert_not_includes @resolved_scope, @api_only_app.signin_permission
          assert_not_includes @resolved_scope, @api_only_app_delegated_permission
          assert_not_includes @resolved_scope, @api_only_app_non_delegated_permission
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
