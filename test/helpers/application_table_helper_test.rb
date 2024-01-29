require "test_helper"

class ApplicationTableHelperTest < ActionView::TestCase
  include PunditHelpers

  context "#update_permissions_link" do
    setup do
      @user = create(:api_user)
    end

    should "generate a link to edit the permissions" do
      application = create(:application, with_supported_permissions: %w[permission])

      assert_includes update_permissions_link(application, @user), edit_api_user_application_permissions_path(@user, application)
    end

    should "return nil when the application has no grantable permissions" do
      application = create(:application)

      assert_nil update_permissions_link(application, @user)
    end

    context "for a user" do
      setup do
        @user = create(:user)
      end

      should "generate a link to edit the permissions" do
        application = create(:application, with_supported_permissions: %w[permission])

        assert_includes update_permissions_link(application, @user), edit_user_application_permissions_path(@user, application)
      end
    end

    context "when no user is provided" do
      should "generate a link to edit the permissions" do
        application = create(:application, with_supported_permissions: %w[permission])

        assert_includes update_permissions_link(application), edit_account_application_permissions_path(application)
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

    should "return nil when the user can do neither" do
      stub_policy @user, [:account, @application]
      assert_nil account_applications_permissions_link(@application)
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
end
