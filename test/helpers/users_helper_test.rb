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
    should "return organisation options suitable for select component" do
      organisation1 = create(:organisation)
      organisation2 = create(:organisation)
      organisations = [organisation1, organisation2]
      stubs(:policy_scope).with(Organisation).returns(organisations)

      options = options_for_organisation_select(selected: organisation2.id)

      expected_options = [
        { text: "None", value: nil },
        { text: organisation1.name, value: organisation1.id },
        { text: organisation2.name, value: organisation2.id, selected: true },
      ]
      assert_equal expected_options, options
    end
  end
end
