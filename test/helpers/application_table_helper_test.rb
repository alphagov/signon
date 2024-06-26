require "test_helper"

class ApplicationTableHelperTest < ActionView::TestCase
  include PunditHelpers

  context "#account_applications_grant_access_link" do
    setup do
      @user = build(:user)
      stubs(:current_user).returns(@user)
      @application = create(:application)
    end

    should "generate a grant access button when the user can grant siginin permission" do
      stub_policy @user, [:account, Doorkeeper::Application], grant_signin_permission?: true
      assert_includes account_applications_grant_access_link(@application), "Grant access"
    end

    should "return an empty string when the user cannot grant signin permission" do
      stub_policy @user, [:account, Doorkeeper::Application], grant_signin_permission?: false
      assert account_applications_grant_access_link(@application).empty?
    end
  end

  context "#users_applications_grant_access_link" do
    setup do
      @application = create(:application)
    end

    should "generate a grant access button when the user can create user application permissions" do
      user = create(:superadmin_user)
      stubs(:current_user).returns(user)

      assert_includes users_applications_grant_access_link(@application, user), "Grant access"
    end

    should "return an empty string when the user cannot create user application permissions" do
      user = create(:user)
      stubs(:current_user).returns(user)

      assert users_applications_grant_access_link(@application, user).empty?
    end
  end

  context "#account_applications_remove_access_link" do
    setup do
      @user = build(:user)
      stubs(:current_user).returns(@user)
      @application = create(:application)
    end

    should "generate an update link when the user can remove signing permissions" do
      stub_policy @user, [:account, @application], remove_signin_permission?: true
      assert_includes account_applications_remove_access_link(@application), "Remove access"
    end

    should "return an empty string when the user cannot remove sigin permissions" do
      stub_policy @user, [:account, @application], remove_signin_permission?: false
      assert account_applications_remove_access_link(@application).empty?
    end
  end

  context "#users_applications_remove_access_link" do
    setup do
      @application = create(:application, with_supported_permissions: %w[permission])
    end

    should "generate a remove access link when the user can delete permissions" do
      user = create(:superadmin_user)
      stubs(:current_user).returns(user)

      assert_includes users_applications_remove_access_link(@application, user), "Remove access"
    end

    should "return an empty string when the user cannot delete permissions" do
      user = create(:user)
      stubs(:current_user).returns(user)

      assert users_applications_remove_access_link(@application, user).empty?
    end
  end

  context "#account_applications_permissions_link" do
    setup do
      @user = build(:user)
      stubs(:current_user).returns(@user)
      @application = create(:application, with_supported_permissions: %w[permission])
    end

    should "generate an update link when the user can edit permissions" do
      stub_policy @user, [:account, @application], edit_permissions?: true
      assert_includes account_applications_permissions_link(@application), "Update permissions"
    end

    should "generate a view link when the user can view permissions" do
      stub_policy @user, [:account, @application], view_permissions?: true
      assert_includes account_applications_permissions_link(@application), "View permissions"
    end

    should "return an empty string when the user can do neither" do
      stub_policy @user, [:account, @application]
      assert account_applications_permissions_link(@application).empty?
    end
  end

  context "#users_applications_permissions_link" do
    setup do
      @application = create(:application, with_supported_permissions: %w[permission])
    end

    should "generate an update link when the user can edit permissions" do
      user = create(:superadmin_user)
      stubs(:current_user).returns(user)

      assert_includes users_applications_permissions_link(@application, user), "Update permissions"
    end

    should "generate a view link when the user cannot edit permissions" do
      user = create(:user)
      stubs(:current_user).returns(user)

      assert_includes users_applications_permissions_link(@application, user), "View permissions"
    end
  end

  context "#api_users_applications_permissions_link" do
    should "generate an update link when the user can edit permissions" do
      application = create(:application, with_supported_permissions: %w[permission])
      user = create(:superadmin_user)
      stubs(:current_user).returns(user)

      assert_includes api_users_applications_permissions_link(application, user), "Update permissions"
    end
  end

  context "#grant_access_link" do
    should "generate a link to grant access to the application" do
      application = create(:application)

      assert_includes grant_access_link(application), account_application_signin_permission_path(application)
    end

    context "when given a user" do
      should "generate a link to grant the user access to the application" do
        application = create(:application)
        user = create(:user)

        assert_includes grant_access_link(application, user), user_application_signin_permission_path(user, application)
      end
    end
  end

  context "#remove_access_link" do
    should "generate a link to remove access to the application" do
      application = create(:application)

      assert_includes remove_access_link(application), delete_account_application_signin_permission_path(application)
    end

    context "when provided with a user" do
      setup do
        @user = create(:user)
      end

      should "generate a link to remove users access to the application" do
        application = create(:application)

        assert_includes remove_access_link(application, @user), delete_user_application_signin_permission_path(@user, application)
      end
    end
  end

  context "#view_permissions_link" do
    should "generate a link to view the permissions" do
      application = create(:application, with_supported_permissions: %w[permission])

      assert_includes view_permissions_link(application), account_application_permissions_path(application)
    end

    context "when provided with a user" do
      setup do
        @user = create(:user)
      end

      should "generate a link to view the permissions" do
        application = create(:application, with_supported_permissions: %w[permission])

        assert_includes view_permissions_link(application, @user), user_application_permissions_path(@user, application)
      end
    end
  end

  context "#update_permissions_link" do
    context "when the application has grantable permissions" do
      setup do
        @application = create(:application, with_supported_permissions: %w[permission])
      end

      context "when no user is provided" do
        should "generate a link to edit own permissions" do
          assert_includes update_permissions_link(@application), edit_account_application_permissions_path(@application)
        end
      end

      context "with a given normal user" do
        should "generate a link to edit the user's permissions" do
          user = create(:user)

          assert_includes update_permissions_link(@application, user), edit_user_application_permissions_path(user, @application)
        end
      end

      context "with a given API user" do
        should "generate a link to edit the API user's permissions" do
          user = create(:api_user)

          assert_includes update_permissions_link(@application, user), edit_api_user_application_permissions_path(user, @application)
        end
      end
    end

    context "when the application has no grantable permissions" do
      should "return an empty string" do
        application = create(:application)

        assert update_permissions_link(application).empty?
      end
    end
  end
end
