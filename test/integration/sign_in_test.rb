require 'test_helper'

class SignInTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "email@example.com", password: "some passphrase with various $ymb0l$")
  end

  should "display a confirmation for successful sign-ins" do
    visit root_path
    signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")
  end

  should "display a rejection for unsuccessful sign-ins" do
    visit root_path
    signin_with(email: "email@example.com", password: "some incorrect passphrase with various $ymb0l$")
    assert_response_contains("Invalid email or passphrase")
  end

  should "display the same rejection for failed logins, empty passwords, and missing accounts" do
    visit root_path
    signin_with(email: "does-not-exist@example.com", password: "some made up p@ssw0rd")
    assert_response_contains("Invalid email or passphrase")

    visit root_path
    signin_with(email: "email@example.com", password: "some incorrect passphrase with various $ymb0l$")
    assert_response_contains("Invalid email or passphrase")

    visit root_path
    signin_with(email: "email@example.com", password: "")
    assert_response_contains("Invalid email or passphrase")
  end

  should "succeed if the Client-IP header is set" do
    page.driver.browser.header("Client-IP", "127.0.0.1")

    visit root_path
    signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
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
    signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")

    ReauthEnforcer.expects(:perform_on).never

    Timecop.travel(User.timeout_in + 5.minutes)

    visit root_path
    signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
    assert_response_contains("Signed in successfully.")
  end

  context "with a 2SV secret key" do
    setup do
      @user.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)
    end

    should "prompt for a verification code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)
      assert_response_contains "get your code"
      assert_selector "input[name=code]"
    end

    should "not prompt for a verification code twice per browser in 30 days" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to"

      signout
      visit root_path

      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)
      assert_response_contains "Welcome to"

      signout
      visit root_path

      Timecop.travel(30.days.from_now + 1) do
        visit root_path
        signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
        assert_response_contains "Welcome to"
      end
    end

    should "prevent access to signon until fully authenticated" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)
      visit root_path
      assert_response_contains "get your code"
      assert_selector "input[name=code]"
    end

    should "allow access with a correctly-generated code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to"
      assert_response_contains "Signed in successfully"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFIED.id, uid: @user.uid).count
    end

    should "prevent access with a blank code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: "")

      assert_response_contains "get your code"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFICATION_FAILED.id, uid: @user.uid).count
    end

    should "prevent access with an old code" do
      old_code = Timecop.freeze(2.minutes.ago) { ROTP::TOTP.new(@user.otp_secret_key).now }

      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: old_code)

      assert_response_contains "get your code"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFICATION_FAILED.id, uid: @user.uid).count
    end

    should "prevent access with a garbage code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: "abcdef")

      assert_response_contains "get your code"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFICATION_FAILED.id, uid: @user.uid).count
    end

    should "prevent access if max attempts reached" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)

      Timecop.freeze do
        User::MAX_2SV_LOGIN_ATTEMPTS.times do
          fill_in :code, with: "abcdef"
          click_button "Sign in"
        end

        assert_response_contains 1.hour.from_now.to_s(:govuk_time)
      end
      assert_response_contains "entered too many times"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_LOCKED.id, uid: @user.uid).count
    end

    should "not permit an expired cookie to be used to bypass 2SV" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      remember_2sv_session = Capybara.current_session.driver.request.cookies["remember_2sv_session"]

      Timecop.travel(30.days.from_now + 1) do
        # Force Capybara's driver to clear the expired cookie from the session, then manually set
        # the same value but with a future expiry
        visit root_path
        Capybara.current_session.driver.request.cookies["remember_2sv_session"] = remember_2sv_session

        visit root_path
        signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)
        assert_response_contains "get your code"
        assert_selector "input[name=code]"
      end
    end

    should "not permit another user's cookie to be used to bypass 2SV" do
      attacker = create(:user, email: "attacker@example.com", password: "c0mpl£x $ymb0l$")
      attacker.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)

      visit root_path
      signin_with(email: "attacker@example.com", password: "c0mpl£x $ymb0l$")
      remember_2sv_session = Capybara.current_session.driver.request.cookies["remember_2sv_session"]
      signout

      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)
      Capybara.current_session.driver.request.cookies["remember_2sv_session"] = remember_2sv_session
      visit root_path
      assert_response_contains "get your code"
      assert_selector "input[name=code]"
    end

    should "not remember a user's 2SV session if they've changed 2SV secret" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to"

      signout
      visit root_path

      @user.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)

      assert_response_contains "get your code"
      assert_selector "input[name=code]"
    end

    should "not prevent login if 2SV is disabled for user with a remembered session" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$")
      assert_response_contains "Welcome to"

      signout
      visit root_path

      @user.update_attribute(:otp_secret_key, nil)
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)

      assert_response_contains "Signed in successfully"
    end

    should "allow the user to cancel 2SV by signing out" do
      visit root_path
      signin_with(email: "email@example.com", password: "some passphrase with various $ymb0l$", second_step: false)
      click_link "Sign out"

      assert_text "Signed out successfully."
    end
  end

  should "not display a link to resend unlock instructions" do
    visit root_path
    refute_selector "a", text: "Didn't receive unlock instructions?"
  end

  should "not be able to access the 2SV login page before logging in" do
    signout
    visit new_two_step_verification_session_path
    assert_response_contains("You need to sign in before continuing.")
  end
end
