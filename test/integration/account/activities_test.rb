require "test_helper"

class Account::ActivitiesTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "list user's EventLogs in table" do
      user = create(:user)

      visit new_user_session_path
      signin_with user

      visit account_activity_path

      assert page.has_selector? "td", text: "Successful login"
    end
    should "not show technical events to normal users" do
      user = create(:user)
      EventLog.record_event(user, EventLog::ACCESS_GRANTS_DELETED)

      visit new_user_session_path
      signin_with user

      visit account_activity_path

      assert page.has_selector? "td", text: "Successful login"
      assert_no_text "Access grants deleted"
    end

    should "show technical events to admin/superadmin users" do
      user = create(:admin_user)
      EventLog.record_event(user, EventLog::ACCESS_GRANTS_DELETED)

      visit new_user_session_path
      signin_with user

      visit account_activity_path

      assert page.has_selector? "td", text: "Successful login"
      assert page.has_selector? "td", text: "Access grants deleted"
    end
  end
end
