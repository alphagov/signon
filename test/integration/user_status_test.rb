require "test_helper"
require "support/password_helpers"

class UserStatusTest < ActionDispatch::IntegrationTest
  include PasswordHelpers

  setup do
    @admin = create(:admin_user)
    @user = create(:user, suspended_at: 1.days.ago, reason_for_suspension: "Inactivity")
  end

  test "User status appears on the edit user page" do
    visit root_path
    signin_with(@admin)
    visit user_path(@user)

    assert page.has_content?("suspended")
  end
end
