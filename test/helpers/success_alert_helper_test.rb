require "test_helper"

class SuccessAlertHelperTest < ActionView::TestCase
  context "#access_and_permissions_granted_params" do
    setup do
      @application = create(:application)
      stubs(:current_user).returns(create(:user))
    end

    context "when granting access" do
      should "return success alert params with the `access_granted_message` text" do
        stubs(:access_granted_message).returns("Granted access")

        expected = { message: "Access granted", description: "Granted access" }
        assert_equal expected, access_and_permissions_granted_params(@application.id, granting_access: true)
      end
    end

    context "when updating permissions" do
      should "return success alert params with the `message_for_success` text" do
        stubs(:message_for_success).returns("Added permissions")

        expected = { message: "Permissions updated", description: "Added permissions" }
        assert_equal expected, access_and_permissions_granted_params(@application.id, granting_access: false)
      end
    end
  end

  context "#access_removed_params" do
    setup do
      @application = create(:application)
      stubs(:current_user).returns(create(:user))
    end

    context "when removing access" do
      should "return success alert params with the `access_removed_message` text" do
        stubs(:access_removed_message).returns("You've got no access")

        expected = { message: "Access removed", description: "You've got no access" }
        assert_equal expected, access_removed_params(@application.id)
      end
    end
  end
end
