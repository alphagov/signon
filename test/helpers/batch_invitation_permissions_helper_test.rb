require "test_helper"

class BatchInvitationPermissionsHelperTest < ActionView::TestCase
  context "#formatted_permission_name" do
    should "return the permission name if permission is not the signin permission" do
      assert_equal "Editor", formatted_permission_name("Whitehall", "Editor")
    end

    should "include the application name if permission is the signin permission" do
      assert_equal "Has access to Whitehall?", formatted_permission_name("Whitehall", SupportedPermission::SIGNIN_NAME)
    end
  end
end
