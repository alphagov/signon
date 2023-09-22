require "test_helper"

class AccountTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "not be accessible to signed out users" do
      visit account_path

      assert_current_url new_user_session_path
    end

    should "link to Change email/password and Manage permissions for admin users" do
      user = FactoryBot.create(:admin_user)

      visit new_user_session_path
      signin_with user

      visit account_path
      assert_current_url account_path
      assert page.has_selector?("h1", text: "Settings")

      assert page.has_link?("Change your email or password", href: account_email_password_path)
      assert page.has_link?("Manage permissions", href: account_manage_permissions_path)
    end

    should "link to Change email/password for normal users" do
      user = FactoryBot.create(:user)

      visit new_user_session_path
      signin_with user

      visit account_path
      assert page.has_selector?("h1", text: "Settings")

      assert page.has_link?("Change your email or password", href: account_email_password_path)

      assert_not page.has_link?("Manage permissions")
    end
  end
end
