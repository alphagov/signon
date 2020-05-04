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

    @gds_editor = create(:user, with_permissions: { "Specialist Publisher" => %w[editor gds_editor signin] })
    @editor = create(:user, with_permissions: { "Specialist Publisher" => %w[editor signin] })
    @writer = create(:user, with_permissions: { "Specialist Publisher" => %w[signin] })
    @user_without_access = create(:user)
    @user_with_unrelated_access = create(:user, with_permissions: { "unrelated application" => %w[editor gds_editor signin] })
  end

  should "copy permissions over for all users of an application to another application" do
    UserPermissionMigrator.migrate(
      source: "Specialist Publisher",
      target: "Manuals Publisher",
    )

    assert_equal %w[editor gds_editor signin], @gds_editor.permissions_for(@manuals_publisher)
    assert_equal %w[editor signin], @editor.permissions_for(@manuals_publisher)
    assert_equal %w[signin], @writer.permissions_for(@manuals_publisher)
    assert_equal %w[], @user_without_access.permissions_for(@manuals_publisher)
    assert_equal %w[], @user_with_unrelated_access.permissions_for(@manuals_publisher)

    assert_equal %w[editor gds_editor signin], @gds_editor.permissions_for(@specialist_publisher)
    assert_equal %w[editor signin], @editor.permissions_for(@specialist_publisher)
    assert_equal %w[signin], @writer.permissions_for(@specialist_publisher)
    assert_equal %w[], @user_without_access.permissions_for(@specialist_publisher)
    assert_equal %w[], @user_with_unrelated_access.permissions_for(@specialist_publisher)
  end
end
