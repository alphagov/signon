require "test_helper"

class AccountTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "not be accessible to signed out users" do
      visit account_path

      assert_current_url new_user_session_path
    end

    should "link to Change email/password, Manage permissions, Change 2SV and Role/org for admin users" do
      user = FactoryBot.create(:admin_user, otp_secret_key: "2SVenabled")

      visit new_user_session_path
      signin_with user

      visit account_path
      assert_current_url account_path
      assert page.has_selector?("h1", text: "Settings")

      assert page.has_link?("Change your email or password", href: account_email_password_path)
      assert page.has_link?("Manage permissions", href: account_manage_permissions_path)
      assert page.has_link?("Change your 2-step verification phone", href: two_step_verification_path)
      assert page.has_link?("Change your role or organisation", href: account_role_organisation_path)
      assert page.has_link?("Your account access log", href: account_activity_path)
    end

    should "link to Change email/password, Change 2SV and Role/org for normal users" do
      user = FactoryBot.create(:user, otp_secret_key: "2SVenabled")

      visit new_user_session_path
      signin_with user

      visit account_path
      assert page.has_selector?("h1", text: "Settings")

      assert page.has_link?("Change your email or password", href: account_email_password_path)
      assert page.has_link?("Change your 2-step verification phone", href: two_step_verification_path)
      assert page.has_link?("View your role and organisation", href: account_role_organisation_path)
      assert page.has_link?("Your account access log", href: account_activity_path)

      assert_not page.has_link?("Manage permissions")
    end

    should "link to 2SV setup page for users who don't already have it" do
      user = FactoryBot.create(:user)

      visit new_user_session_path
      signin_with user

      visit account_path
      assert page.has_selector?("h1", text: "Settings")

      assert page.has_link?("Set up 2-step verification", href: two_step_verification_path)
    end
  end
end
