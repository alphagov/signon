require "test_helper"
require "support/policy_helpers"

class Account::UserApplicationPermissionPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "#show?" do
    setup do
      @current_user = create(:user)
      target_user = create(:user)
      @user_application_permission = create(:user_application_permission, user: target_user)

      @policy = stub(:policy)
      Pundit.stubs(:policy).with(target_user).returns(@policy)
    end

    should "return true if the current user can edit the target user" do
      @policy.stubs(:edit?).returns(true)

      assert permit?(@current_user, @user_application_permission, :show)
    end

    should "return false if the current user cannot edit the target user" do
      @policy.stubs(:edit?).returns(false)

      assert forbid?(@current_user, @user_application_permission, :show)
    end
  end

  [:edit, :delete].each do |method|
    context method do
      setup do
        @target_user = create(:user)
      end

      context "when the current user cannot edit the target user" do
        setup do
          policy = stub(:policy, edit?: false)
          Pundit.stubs(:policy).with(@target_user).returns(policy)
        end

        should "return false" do
          current_user = create(:user)
          user_application_permission = create(:user_application_permission, user: @target_user)

          assert forbid?(current_user, user_application_permission, method)
        end
      end

      context "when the current user can edit the target user" do
        setup do
          policy = stub(:policy, edit?: true)
          Pundit.stubs(:policy).with(@target_user).returns(policy)
        end

        should "return true the current user is a govuk admin" do
          current_user = create(:superadmin_user)
          user_application_permission = create(:user_application_permission, user: @target_user)

          assert permit?(current_user, user_application_permission, method)
        end

        should "return false if the current user does not have access to the application" do
          current_user = create(:super_organisation_admin_user)
          user_application_permission = create(:user_application_permission, user: @target_user)

          assert forbid?(current_user, user_application_permission, method)
        end

        should "return false if the current user has access to the application but the application does not have delegatable permissions" do
          current_user = create(:super_organisation_admin_user)
          application = create(:application)
          application.signin_permission.update(delegatable: false)
          user_application_permission = create(:user_application_permission, user: @target_user, application: )
          current_user.grant_application_signin_permission(application)

          assert forbid?(current_user, user_application_permission, method)
        end

        should "return true if the current user has access to the application and the application has delegatable permissions" do
          current_user = create(:super_organisation_admin_user)
          application = create(:application)
          user_application_permission = create(:user_application_permission, user: @target_user, application: )
          current_user.grant_application_signin_permission(application)

          assert permit?(current_user, user_application_permission, method)
        end
      end
    end
  end
end
