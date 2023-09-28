require "test_helper"

class AccountActivitiesTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "list user's EventLogs in table" do
      user = create(:user)

      visit new_user_session_path
      signin_with user

      visit account_activity_path

      assert page.has_selector? "td", text: "Successful login"
    end
  end
end
