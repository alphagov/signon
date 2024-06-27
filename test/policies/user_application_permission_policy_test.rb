require "test_helper"
require "support/policy_helpers"

class UserApplicationPermissionPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers
  include PunditHelpers

  %i[create destroy delete update edit].each do |policy_method|
    context "#{policy_method}?" do
      setup do
        @application = create(:application)
        @supported_permission = create(:supported_permission, application: @application, delegatable: true)
        @current_user = create(:superadmin_user, :in_organisation)
        @user = create(:user)
        @user_application_permission = UserApplicationPermission.for(user: @user, supported_permission: @supported_permission, application: @application)

        @current_user.grant_application_signin_permission(@application)
        @user.grant_application_signin_permission(@application)
      end

      context "when the current user is allowed to edit the target user" do
        setup { stub_policy(@current_user, @user, edit?: true) }

        [Roles::Superadmin.name, Roles::Admin.name].each do |govuk_admin_role|
          context "and the current user is a(n) #{govuk_admin_role}" do
            setup { @current_user.update!(role: govuk_admin_role) }
            should("be allowed") { assert permit?(@current_user, @user_application_permission, policy_method) }
          end
        end

        [Roles::SuperOrganisationAdmin.name, Roles::OrganisationAdmin.name].each do |publishing_manager_role|
          context "and the current user is a #{publishing_manager_role}" do
            setup { @current_user.update!(role: publishing_manager_role) }

            context "with access to the application and for a delegatable permission" do
              should("be allowed") { assert permit?(@current_user, @user_application_permission, policy_method) }
            end

            context "without access to the application" do
              setup do
                UserApplicationPermission.find_by(
                  user: @current_user,
                  application: @application,
                  supported_permission: @application.signin_permission,
                ).destroy
              end

              should("not be allowed") { assert forbid?(@current_user, @user_application_permission, policy_method) }
            end

            context "for a non-delegatable permission" do
              setup { @supported_permission.update!(delegatable: false) }
              should("not be allowed") { assert forbid?(@current_user, @user_application_permission, policy_method) }
            end
          end
        end
      end

      context "when the current user is not allowed to edit the target user" do
        setup { stub_policy(@current_user, @user, edit?: false) }
        should("not be allowed") { assert forbid?(@current_user, @user_application_permission, policy_method) }
      end
    end
  end
end
