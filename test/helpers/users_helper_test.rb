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
end
