require "test_helper"

class AccountApplicationsHelperTest < ActionView::TestCase
  context "#message_for_success" do
    setup do
      @application = create(:application, name: "Whitehall", with_supported_permissions: ["Permission 1"])
      user = create(:user, with_permissions: { @application => ["Permission 1", SupportedPermission::SIGNIN_NAME] })
      stubs(:current_user).returns(user)
    end

    should "include the application name in the message" do
      assert_includes message_for_success(@application.id), "You now have the following permissions for Whitehall"
    end

    should "include the users permissions in the message" do
      assert_includes message_for_success(@application.id), "Permission 1"
    end

    should "not include the signin permission in the message" do
      assert_not_includes message_for_success(@application.id), "signin"
    end

    context "when the application does not exist" do
      should "return nil" do
        assert_nil message_for_success(:made_up_id)
      end
    end
  end
end
