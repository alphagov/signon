require "test_helper"

class CookiesSecurityTest < ActionDispatch::IntegrationTest
  should "set the right cookies when signing in" do
    user = FactoryBot.create(:two_step_enabled_user)
    sign_up_with user.email, user.password
    visit new_user_session_path
    response_cookies = Capybara.current_session.driver.response.headers["Set-Cookie"]
    assert_match "HttpOnly", response_cookies
    assert_match "SameSite=Lax", response_cookies
  end

  def sign_up_with(email, password)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Sign in"
  end
end
