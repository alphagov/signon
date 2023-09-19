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

  context "#permissions_for" do
    should "return all of the supported permissions that are grantable from the ui" do
      application = create(:application,
                           name: "Whitehall",
                           with_supported_permissions: ["Editor", SupportedPermission::SIGNIN_NAME],
                           with_supported_permissions_not_grantable_from_ui: ["Not grantable"])

      permission_names = permissions_for(application).map(&:name)

      assert permission_names.include?("Editor")
      assert permission_names.include?(SupportedPermission::SIGNIN_NAME)
      assert_not permission_names.include?("Not grantable")
    end

    should "sort the permissions alphabetically by name, but with the signin permission first" do
      application = create(:application,
                           name: "Whitehall",
                           with_supported_permissions: ["Writer", "Editor", SupportedPermission::SIGNIN_NAME])

      permission_names = permissions_for(application).map(&:name)

      assert_equal [SupportedPermission::SIGNIN_NAME, "Editor", "Writer"], permission_names
    end
  end
end
