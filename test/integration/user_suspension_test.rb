require "test_helper"

class UserSuspensionTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @user.suspend("gross misconduct")
  end

  should "prevent users from signing in" do
    visit new_user_session_path
    signin_with(@user)

    assert_response_contains("account has been suspended")
  end

  should "show the suspension reason to admins" do
    admin = create(:user, role: "admin")
    visit new_user_session_path
    signin_with(admin)

    visit edit_user_path(@user)
    assert_response_contains("gross misconduct")
  end
end
