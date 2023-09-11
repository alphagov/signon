require "test_helper"

class AccountTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "not be accessible to signed out users" do
      visit account_path

      assert_current_url new_user_session_path
    end

    should "redirect to user's edit page for admin users" do
      user = FactoryBot.create(:admin_user)

      visit new_user_session_path
      signin_with user

      visit account_path

      assert_current_url edit_user_path(user)
    end

    should "redirect to edit email or password page for normal users" do
      user = FactoryBot.create(:user)

      visit new_user_session_path
      signin_with user

      visit account_path

      assert_current_url edit_email_or_password_user_path(user)
    end
  end
end
