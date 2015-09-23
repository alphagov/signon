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

  should "display the same rejection for failed logins, empty passwords, and missing accounts" do
    visit root_path
    signin(email: "does-not-exist@example.com", password: "some made up p@ssw0rd")
    assert_response_contains("Invalid email or passphrase")

    visit root_path
    signin(email: "email@example.com", password: "some incorrect passphrase with various $ymb0l$")
    assert_response_contains("Invalid email or passphrase")

    visit root_path
    signin(email: "email@example.com", password: "")
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

    find('#new_user input[name=authenticity_token]', visible: false).set('not_the_authenticity_token')

    fill_in "Email", with: @user.email
    fill_in "Passphrase", with: @user.password
    click_button "Sign in"
    assert_response_contains("You need to sign in before continuing.")
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

  context "with a 2SV secret key" do
    setup do
      @user.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)
    end

    should "prompt for a verification code" do
      visit root_path
      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "get your code"
      assert_selector "input[name=code]"
    end

    should "not prompt for a verification code twice per browser in 30 days" do
      visit root_path
      signin_with_2sv(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to GOV.UK"

      signout
      visit root_path

      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to GOV.UK"

      signout
      visit root_path

      Timecop.travel(30.days.from_now + 1) do
        visit root_path
        signin_with_2sv(email: "email@example.com", password: "some passphrase with various $ymb0l$")
        assert_response_contains "Welcome to GOV.UK"
      end
    end

    should "prevent access to signon until fully authenticated" do
      visit root_path
      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      visit root_path
      assert_response_contains "get your code"
      assert_selector "input[name=code]"
    end

    should "allow access with a correctly-generated code" do
      visit root_path
      signin_with_2sv(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to GOV.UK"
      assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_VERIFIED, uid: @user.uid).count
    end

    should "prevent access with a blank code" do
      visit root_path
      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      Timecop.freeze do
        fill_in :code, with: ""
        click_button "Sign in"
      end

      assert_response_contains "get your code"
      assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_VERIFICATION_FAILED, uid: @user.uid).count
    end

    should "prevent access with an old code" do
      old_code = Timecop.freeze(2.minutes.ago) { ROTP::TOTP.new(@user.otp_secret_key).now }

      visit root_path
      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      fill_in :code, with: old_code
      click_button "Sign in"

      assert_response_contains "get your code"
      assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_VERIFICATION_FAILED, uid: @user.uid).count
    end

    should "prevent access with a garbage code" do
      visit root_path
      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      fill_in :code, with: "abcdef"
      click_button "Sign in"

      assert_response_contains "get your code"
      assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_VERIFICATION_FAILED, uid: @user.uid).count
    end

    should "prevent access if max attempts reached" do
      @user.update_attribute(:second_factor_attempts_count, User::MAX_2SV_LOGIN_ATTEMPTS)
      visit root_path
      signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")

      assert_response_contains "entered too many times"
      assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_LOCKED, uid: @user.uid).count
    end

    should "not permit an expired cookie to be used to bypass 2SV" do
      visit root_path
      signin_with_2sv(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      remember_2sv_session = Capybara.current_session.driver.request.cookies["remember_2sv_session"]

      Timecop.travel(30.days.from_now + 1) do
        # Force Capybara's driver to clear the expired cookie from the session, then manually set
        # the same value but with a future expiry
        visit root_path
        Capybara.current_session.driver.request.cookies["remember_2sv_session"] = remember_2sv_session

        visit root_path
        signin(email: "email@example.com", password: "some passphrase with various $ymb0l$")
        assert_response_contains "get your code"
        assert_selector "input[name=code]"
      end
    end
  end
end
