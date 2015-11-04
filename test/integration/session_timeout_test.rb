require 'test_helper'

class SessionTimeoutTest < ActionDispatch::IntegrationTest
  setup do
    @user_email = "email@example.com"
    @user_password = "some passphrase with various $ymb0l$"
    @user = create(:user, email: @user_email, password: @user_password)
  end

  should "not extend an expired session by viewing the login form" do
    Timecop.freeze((User.timeout_in + 5.minutes).ago) do
      visit root_path
      signin_with(email: @user_email, password: @user_password)
    end

    visit "/users/sign_in"
    refute_response_contains "You are already signed in"
    assert_response_contains "Sign in"
  end
end
