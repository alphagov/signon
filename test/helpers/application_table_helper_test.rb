require "test_helper"

class ApplicationTableHelperTest < ActionView::TestCase
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
end
