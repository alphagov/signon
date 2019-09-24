require "test_helper"
require "support/password_helpers"

class UserAgentIntegrationTest < ActionDispatch::IntegrationTest
  include PasswordHelpers

  setup do
    @user = create(:user, name: "Normal User")
  end

  test "record user's user-agent string on login" do
    user_agent_test = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
    page.driver.header("User-agent", user_agent_test)
    visit root_path
    signin_with(@user)

    assert_equal user_agent_test, UserAgent.last.user_agent_string
    user_agent = @user.event_logs.first.user_agent_as_string
    assert_equal user_agent_test, user_agent
  end
end
