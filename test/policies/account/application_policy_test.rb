require "test_helper"
require "support/policy_helpers"

class Account::ApplicationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "accessing index?" do
    %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = FactoryBot.build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :index)
        end
      end
    end

    %i[normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = FactoryBot.build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :index)
        end
      end
    end
  end

  context "show?" do
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

  context "#grant_signin_permission?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :grant_signin_permission)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :grant_signin_permission)
        end
      end
    end
  end

  context "#remove_signin_permission?" do
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
            assert permit?(@current_user, @application, :remove_signin_permission)
          end
        end

        context "when the user does not have the signin permission for the app" do
          should "be forbidden" do
            assert forbid?(@current_user, @application, :remove_signin_permission)
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
              assert permit?(@current_user, @application, :remove_signin_permission)
            end
          end

          context "and the application does not have delegatable permissions" do
            setup do
              @application.signin_permission.update!(delegatable: false)
            end

            should "not be permitted" do
              assert forbid?(@current_user, @application, :remove_signin_permission)
            end
          end
        end

        context "when the user does not have the signin permission for the app" do
          should "be forbidden" do
            assert forbid?(@current_user, @application, :remove_signin_permission)
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
          assert forbid?(@current_user, nil, :remove_signin_permission)
        end
      end
    end
  end

  context "#edit_permissions?" do
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
            assert permit?(@current_user, @application, :edit_permissions)
          end
        end

        context "when the user does not have the signin permission for the app" do
          should "be forbidden" do
            assert forbid?(@current_user, @application, :edit_permissions)
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
              assert permit?(@current_user, @application, :edit_permissions)
            end
          end

          context "and the application does not have delegatable permissions" do
            setup do
              @application.signin_permission.update!(delegatable: false)
            end

            should "not be permitted" do
              assert forbid?(@current_user, @application, :edit_permissions)
            end
          end
        end

        context "when the user does not have the signin permission for the app" do
          should "be forbidden" do
            assert forbid?(@current_user, @application, :edit_permissions)
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
          assert forbid?(@current_user, nil, :edit_permissions)
        end
      end
    end
  end
end
