require "test_helper"

class UserPermissionMigrationTest < ActiveSupport::TestCase
  setup do
    @specialist_publisher = create(:application, name: "Specialist Publisher")
    @manuals_publisher = create(:application, name: "Manuals Publisher")
    @unrelated_application = create(:application, name: "unrelated application")

    create(:supported_permission, application: @specialist_publisher, name: "gds_editor")
    create(:supported_permission, application: @specialist_publisher, name: "editor")

    create(:supported_permission, application: @manuals_publisher, name: "gds_editor")
    create(:supported_permission, application: @manuals_publisher, name: "editor")

    create(:supported_permission, application: @unrelated_application, name: "gds_editor")
    create(:supported_permission, application: @unrelated_application, name: "editor")

    @gds_editor = create(:user, with_permissions: { "Specialist Publisher" => ["editor", "gds_editor", SupportedPermission::SIGNIN_NAME] })
    @editor = create(:user, with_permissions: { "Specialist Publisher" => ["editor", SupportedPermission::SIGNIN_NAME] })
    @writer = create(:user, with_permissions: { "Specialist Publisher" => [SupportedPermission::SIGNIN_NAME] })
    @user_without_access = create(:user)
    @user_with_unrelated_access = create(:user, with_permissions: { "unrelated application" => ["editor", "gds_editor", SupportedPermission::SIGNIN_NAME] })
  end

  should "copy permissions over for all users of an application to another application" do
    UserPermissionMigrator.migrate(
      source: "Specialist Publisher",
      target: "Manuals Publisher",
    )

    assert_equal ["editor", "gds_editor", SupportedPermission::SIGNIN_NAME], @gds_editor.permissions_for(@manuals_publisher)
    assert_equal ["editor", SupportedPermission::SIGNIN_NAME], @editor.permissions_for(@manuals_publisher)
    assert_equal [SupportedPermission::SIGNIN_NAME], @writer.permissions_for(@manuals_publisher)
    assert_equal %w[], @user_without_access.permissions_for(@manuals_publisher)
    assert_equal %w[], @user_with_unrelated_access.permissions_for(@manuals_publisher)

    assert_equal ["editor", "gds_editor", SupportedPermission::SIGNIN_NAME], @gds_editor.permissions_for(@specialist_publisher)
    assert_equal ["editor", SupportedPermission::SIGNIN_NAME], @editor.permissions_for(@specialist_publisher)
    assert_equal [SupportedPermission::SIGNIN_NAME], @writer.permissions_for(@specialist_publisher)
    assert_equal %w[], @user_without_access.permissions_for(@specialist_publisher)
    assert_equal %w[], @user_with_unrelated_access.permissions_for(@specialist_publisher)
  end
end
