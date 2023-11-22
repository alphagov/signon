require "test_helper"
require "support/policy_helpers"

class Account::UserApplicationPermissionPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "#show?" do
    %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :show)
        end
      end
    end

    %i[normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :show)
        end
      end
    end
  end

  context "#delete?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = create(:"#{user_role}_user")
          @application = create(:application)
        end

        context "when the user has signin permission for the app" do
          setup do
            @current_user.grant_application_signin_permission(@application)
          end

          should "be permitted" do
            assert permit?(@current_user, @current_user.signin_permission_for(@application), :delete)
          end
        end

        context "when the user does not have the signin permission for the app" do
          should "be forbidden" do
            assert forbid?(@current_user, @current_user.signin_permission_for(@application), :delete)
          end
        end
      end
    end

    %i[super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = create(:"#{user_role}_user")
          @application = create(:application)
        end

        context "when the user has signin permission for the app" do
          setup do
            @current_user.grant_application_signin_permission(@application)
          end

          context "and the application has delegatable permissions" do
            setup do
              @application.signin_permission.update!(delegatable: true)
            end

            should "be permitted" do
              assert permit?(@current_user, @current_user.signin_permission_for(@application), :delete)
            end
          end

          context "and the application does not have delegatable permissions" do
            setup do
              @application.signin_permission.update!(delegatable: false)
            end

            should "not be permitted" do
              assert forbid?(@current_user, @current_user.signin_permission_for(@application), :delete)
            end
          end
        end

        context "when the user does not have the signin permission for the app" do
          should "be forbidden" do
            assert forbid?(@current_user, @current_user.signin_permission_for(@application), :delete)
          end
        end
      end
    end

    %i[normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :delete)
        end
      end
    end
  end
end
