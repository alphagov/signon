require 'test_helper'
 
class UserSuspensionTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @user.suspend("gross misconduct")
  end

  should "prevent users from signing in" do
    visit new_user_session_path
    signin(@user)

    assert_response_contains("account has been temporarily suspended")
  end

  should "show the suspension reason to admins" do
    admin = create(:user, role: 'admin')
    visit new_user_session_path
    signin(admin)

    visit edit_admin_user_path(@user)
    assert_response_contains("gross misconduct")
  end
end
