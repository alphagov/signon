require 'test_helper'

class SignInTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "email@example.com", password: "some passphrase with various $ymb0l$")
  end

  should "display a confirmation for successful sign-ins" do
    visit root_path
    signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")
  end

  should "display a rejection for unsuccessful sign-ins" do
    visit root_path
    signin(email: "email@example.com", password: "some incorrect passphrase with various $ymb0l$")
    assert_response_contains("Invalid email or passphrase")
  end

  should "succeed if the Client-IP header is set" do
    page.driver.browser.header("Client-IP", "127.0.0.1")

    visit root_path
    signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")
  end

  should "not accept the login with an invalid CSRF token" do
    visit root_path

    find('#new_user input[name=authenticity_token]').set('not_the_authenticity_token')

    fill_in "Email", with: @user.email
    fill_in "Passphrase", with: @user.password
    click_button "Sign in"
    assert_response_contains("You need to sign in or sign up before continuing.")
  end

  should "not remotely sign out user when visiting with an expired session cookie" do
    visit root_path
    signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")

    ReauthEnforcer.expects(:perform_on).never

    Timecop.travel(User.timeout_in + 5.minutes)

    visit root_path
    signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")
  end
end
