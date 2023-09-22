require "test_helper"

class AccountTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "not be accessible to signed out users" do
      visit account_path

      assert_current_url new_user_session_path
    end

    should "link to Change email/password" do
      user = FactoryBot.create(:user)

      visit new_user_session_path
      signin_with user

      visit account_path
      assert page.has_selector?("h1", text: "Settings")

      assert page.has_link?("Change your email or password", href: account_email_password_path)
    end
  end
end
