require "test_helper"

class UsersHelperTest < ActionView::TestCase
  test "sync_needed? should work with user permissions not synced yet" do
    application = create(:application)
    user = create(:user)
    user.grant_application_signin_permission(application)

    assert_nothing_raised { sync_needed?(user.application_permissions) }
  end

  test "two_step_status should reflect the user's status accurately when the user is exempted from 2sv" do
    assert_equal "Exempted", two_step_status(create(:two_step_exempted_user))
  end

  test "two_step_status should reflect the user's status accurately when the user has 2sv set up" do
    assert_equal "Enabled", two_step_status(create(:two_step_enabled_user))
  end

  test "two_step_status should reflect the user's status accurately when the user does not have 2sv set up" do
    assert_equal "Not set up", two_step_status(create(:user))
  end

  context "#filtered_users_heading" do
    setup do
      @users = [build(:user), build(:user)]
      @current_user = build(:user)
      stubs(:formatted_number_of_users).with(@users).returns("2 users")
      stubs(:current_user).returns(@current_user)
      @organisation = build(:organisation)
    end

    should "return formatted number of users" do
      another_organisation = build(:organisation)
      @current_user.stubs(:manageable_organisations).returns([@organisation, another_organisation])

      assert_equal "2 users", filtered_users_heading(@users)
    end

    should "return formatted number of users in specified organisation" do
      @current_user.stubs(:manageable_organisations).returns([@organisation])

      assert_equal "2 users in #{@organisation.name}", filtered_users_heading(@users)
    end
  end

  context "#options_for_role_select" do
    should "return role options suitable for select component" do
      roles = [Roles::Admin.role_name, Roles::Normal.role_name]
      stubs(:assignable_user_roles).returns(roles)

      options = options_for_role_select(selected: Roles::Normal.role_name)

      expected_options = [{ text: "Admin", value: "admin" }, { text: "Normal", value: "normal", selected: true }]
      assert_equal expected_options, options
    end
  end

  context "#options_for_organisation_select" do
    should "return organisation options suitable for select component, sorted alphabetically and exluding closed organisations" do
      user = create(:admin_user)
      stubs(:current_user).returns(user)

      organisation1 = create(:organisation, name: "B Organisation")
      organisation2 = create(:organisation, name: "A Organisation")
      create(:organisation, name: "Closed Organisation", closed: true)

      options = options_for_organisation_select(selected: organisation2.id)

      expected_options = [
        { text: "None", value: nil },
        { text: "A Organisation", value: organisation2.id, selected: true },
        { text: "B Organisation", value: organisation1.id },
      ]
      assert_equal expected_options, options
    end
  end

  context "#items_for_permission_checkboxes" do
    should "return permission options suitable for checkboxes component" do
      application = create(:application)
      signin_permission = application.signin_permission
      permission1 = create(:supported_permission, application:, name: "permission1")
      permission2 = create(:supported_permission, application:, name: "permission2")

      user = create(:user, supported_permissions: [signin_permission, permission1])

      items = items_for_permission_checkboxes(application:, user:)

      expected_items = [
        {
          id: supported_permission_checkbox_id(application, signin_permission),
          name: "user[supported_permission_ids][]",
          label: "Has access to #{application.name}?",
          value: signin_permission.id,
          checked: true,
        },
        {
          id: supported_permission_checkbox_id(application, permission1),
          name: "user[supported_permission_ids][]",
          label: "permission1",
          value: permission1.id,
          checked: true,
        },
        {
          id: supported_permission_checkbox_id(application, permission2),
          name: "user[supported_permission_ids][]",
          label: "permission2",
          value: permission2.id,
          checked: false,
        },
      ]

      assert_equal expected_items, items
    end
  end

  context "#formatted_permission_name" do
    should "return the permission name if permission is not the signin permission" do
      assert_equal "Editor", formatted_permission_name("Whitehall", "Editor")
    end

    should "include the application name if permission is the signin permission" do
      assert_equal "Has access to Whitehall?", formatted_permission_name("Whitehall", SupportedPermission::SIGNIN_NAME)
    end
  end
end
