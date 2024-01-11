require "test_helper"

class ApiUsersHelperTest < ActionView::TestCase
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
  end
end
