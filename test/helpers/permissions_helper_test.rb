require "test_helper"

class PermissionsHelperTest < ActionView::TestCase
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
