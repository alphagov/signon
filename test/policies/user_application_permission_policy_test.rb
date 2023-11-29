require "test_helper"
require "support/policy_helpers"

class UserApplicationPermissionPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  include PunditHelpers

  %i[create destroy].each do |policy_method|
    context "#{policy_method}?" do
      setup do
        @user = create(:user)
        @application = create(:application)
        @signin_permission = @user.grant_application_signin_permission(@application)
      end

      should "be allowed for superadmins" do
        current_user = build(:superadmin_user)

        stub_policy(current_user, @user, edit?: true)

        assert permit?(current_user, @signin_permission, policy_method)
      end

      should "be allowed for admins" do
        current_user = build(:admin_user)

        stub_policy(current_user, @user, edit?: true)

        assert permit?(current_user, @signin_permission, policy_method)
      end

      should "be allowed for super org admins when they have access to the application" do
        current_user = build(:super_organisation_admin_user)
        current_user.grant_application_signin_permission(@application)

        stub_policy(current_user, @user, edit?: true)

        assert permit?(current_user, @signin_permission, policy_method)
      end

      should "not be allowed for super org admins when they don't have access to the application" do
        current_user = build(:super_organisation_admin_user)

        stub_policy(current_user, @user, edit?: true)

        assert forbid?(current_user, @signin_permission, policy_method)
      end

      should "be allowed for org admins when they have access to the application" do
        current_user = build(:organisation_admin_user)
        current_user.grant_application_signin_permission(@application)

        stub_policy(current_user, @user, edit?: true)

        assert permit?(current_user, @signin_permission, policy_method)
      end

      should "not be allowed for org admins when they don't have access to the application" do
        current_user = build(:organisation_admin_user)

        stub_policy(current_user, @user, edit?: true)

        assert forbid?(current_user, @signin_permission, policy_method)
      end

      context "when the signin permission is not delegatable" do
        setup do
          @application.signin_permission.update!(delegatable: false)
        end

        should "not be allowed for super org admins" do
          current_user = build(:super_organisation_admin_user)

          stub_policy(current_user, @user, edit?: true)

          assert forbid?(current_user, @signin_permission, policy_method)
        end

        should "not be allowed for org admins" do
          current_user = build(:organisation_admin_user)

          stub_policy(current_user, @user, edit?: true)

          assert forbid?(current_user, @signin_permission, policy_method)
        end
      end

      should "not be allowed if current user is not allowed to edit the target user" do
        current_user = build(:user)

        stub_policy(current_user, @user, edit?: false)

        assert forbid?(current_user, @signin_permission, policy_method)
      end
    end
  end
end
