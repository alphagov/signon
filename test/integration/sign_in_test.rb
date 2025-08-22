require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  setup do
    @organisation = create(:organisation, name: "Ministry of Lindy-hop", slug: "ministry-of-lindy-hop")
    @email = "email@example.com"
    @password = "some password with various $ymb0l$"
    @user = create(:user_in_organisation, email: @email, password: @password, organisation: @organisation)
  end

  should "not include a link to request support" do
    visit root_path
    refute_response_contains("Raise a support request")
  end

  should "display a confirmation for successful sign-ins" do
    visit root_path
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_user_is_signed_in
  end

  should "return to a reasonable length full path" do
    visit account_path(something: "short")
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_equal "http://www.example.com/account?something=short", page.current_url
  end

  should "return to root when the full path is too long" do
    visit account_path(something: "#{'really' * 340}long")
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_user_is_signed_in
    assert_equal "http://www.example.com/", page.current_url
  end

  should "return to root when directly visiting the sign in page" do
    visit new_user_session_path
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_user_is_signed_in
    assert_equal "http://www.example.com/", page.current_url
  end

  should "display a rejection for unsuccessful sign-ins" do
    visit root_path
    signin_with(email: "email@example.com", password: "some incorrect password with various $ymb0l$")
    assert_response_contains("Invalid email or password")
  end

  should "display the same rejection for failed logins, empty passwords, and missing accounts" do
    visit root_path
    signin_with(email: "does-not-exist@example.com", password: "some made up p@ssw0rd")
    assert_response_contains("Invalid email or password")

    visit root_path
    signin_with(email: "email@example.com", password: "some incorrect password with various $ymb0l$")
    assert_response_contains("Invalid email or password")

    visit root_path
    signin_with(email: "email@example.com", password: "")
    assert_response_contains("Invalid email or password")
  end

  should "succeed if the Client-IP header is set" do
    page.driver.browser.header("Client-IP", "127.0.0.1")

    visit root_path
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_user_is_signed_in
  end

  should "not accept the login with an invalid CSRF token" do
    visit root_path

    find("#new_user input[name=authenticity_token]", visible: false).set("not_the_authenticity_token")

    fill_in "Email", with: @user.email
    fill_in "Password", with: @user.password

    assert_raises(ActionController::InvalidAuthenticityToken) do
      click_button "Sign in"
    end
  end

  should "not remotely sign out user when visiting with an expired session cookie" do
    visit root_path
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_user_is_signed_in

    ReauthEnforcer.expects(:perform_on).never

    Timecop.travel(User.timeout_in + 5.minutes)

    visit root_path
    signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
    assert_user_is_signed_in
  end

  context "with a 2SV secret key" do
    setup do
      @user.update(otp_secret_key: ROTP::Base32.random_base32)
    end

    should "prompt for a verification code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)
      assert_response_contains "Enter 6-digit code"
      assert_selector "input[name=code]"
    end

    should "not prompt for a verification code twice per browser in 30 days" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
      assert_user_is_signed_in

      signout
      visit root_path

      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)
      assert_user_is_signed_in

      signout
      visit root_path

      Timecop.travel(30.days.from_now + 1) do
        visit root_path
        signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
        assert_user_is_signed_in
      end
    end

    should "prevent access to signon until fully authenticated" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)
      visit root_path
      assert_response_contains "Enter 6-digit code"
      assert_selector "input[name=code]"
    end

    should "allow access with a correctly-generated code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
      assert_user_is_signed_in
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFIED.id, uid: @user.uid).count
    end

    should "prevent access with a blank code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: "")

      assert_response_contains "Enter 6-digit code"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFICATION_FAILED.id, uid: @user.uid).count
    end

    should "prevent access with an old code" do
      old_code = Timecop.freeze(2.minutes.ago) { ROTP::TOTP.new(@user.otp_secret_key).now }

      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: old_code)

      assert_response_contains "Enter 6-digit code"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFICATION_FAILED.id, uid: @user.uid).count
    end

    should "prevent access with a garbage code" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: "abcdef")

      assert_response_contains "Enter 6-digit code"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_VERIFICATION_FAILED.id, uid: @user.uid).count
    end

    should "not display attempt failed message on success even after failure" do
      attempt_failed = I18n.t("devise.two_step_verification_session.attempt_failed")

      visit root_path

      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: "invalid")
      assert_response_contains attempt_failed

      code = ROTP::TOTP.new(@user.otp_secret_key).now
      fill_in :code, with: code
      click_button "Sign in"

      refute_response_contains attempt_failed
    end

    should "prevent access if max attempts reached" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)

      Timecop.freeze do
        User::MAX_2SV_LOGIN_ATTEMPTS.times do
          fill_in :code, with: "abcdef"
          click_button "Sign in"
        end

        assert_response_contains 1.hour.from_now.to_fs(:govuk_time)
      end
      assert_response_contains "entered too many times"
      assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_LOCKED.id, uid: @user.uid).count
    end

    should "not permit an expired cookie to be used to bypass 2SV" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
      remember_2sv_session = Capybara.current_session.driver.request.cookies["remember_2sv_session"]

      Timecop.travel(30.days.from_now + 1) do
        # Force Capybara's driver to clear the expired cookie from the session, then manually set
        # the same value but with a future expiry
        visit root_path
        Capybara.current_session.driver.request.cookies["remember_2sv_session"] = remember_2sv_session

        visit root_path
        signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)
        assert_response_contains "Enter 6-digit code"
        assert_selector "input[name=code]"
      end
    end

    should "not permit another user's cookie to be used to bypass 2SV" do
      attacker = create(:user, email: "attacker@example.com", password: "c0mpl£x $ymb0l$")
      attacker.update!(otp_secret_key: ROTP::Base32.random_base32)

      visit root_path
      signin_with(email: "attacker@example.com", password: "c0mpl£x $ymb0l$")
      remember_2sv_session = Capybara.current_session.driver.request.cookies["remember_2sv_session"]
      signout

      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)
      Capybara.current_session.driver.request.cookies["remember_2sv_session"] = remember_2sv_session
      visit root_path
      assert_response_contains "Enter 6-digit code"
      assert_selector "input[name=code]"
    end

    should "not remember a user's 2SV session if they've changed 2SV secret" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
      assert_user_is_signed_in

      signout
      visit root_path

      @user.update!(otp_secret_key: ROTP::Base32.random_base32)
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)

      assert_response_contains "Enter 6-digit code"
      assert_selector "input[name=code]"
    end

    should "not prevent login if 2SV is disabled for user with a remembered session" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$")
      assert_user_is_signed_in

      signout
      visit root_path

      @user.update!(otp_secret_key: nil)
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)

      assert_user_is_signed_in
    end

    should "allow the user to cancel 2SV by signing out" do
      visit root_path
      signin_with(email: "email@example.com", password: "some password with various $ymb0l$", second_step: false)
      click_link "Sign out"

      assert assert_text "Sign in to GOV.UK"
    end

    should "not be able to access restricted paths before completing 2SV" do
      visit root_path
      signin_with(email: @email, password: @password, second_step: false)
      assert_equal new_two_step_verification_session_path, page.current_path

      # TODO: This list should be complete
      restricted_paths = [
        oauth_authorization_path,
        new_user_password_path,
        edit_user_password_path,
        new_user_confirmation_path,
        user_confirmation_path,
        accept_user_invitation_path,
        remove_user_invitation_path,
        new_user_invitation_path,
        new_two_step_verification_session_path,
        prompt_two_step_verification_path,
        two_step_verification_path,
        users_path,
        organisations_path,
        doorkeeper_applications_path,
        api_users_path,
      ]

      restricted_paths.each do |path|
        visit path
        assert_equal new_two_step_verification_session_path, page.current_path
      end
    end
  end

  should "not display a link to resend unlock instructions" do
    visit root_path
    assert assert_no_selector "a", text: "Didn't receive unlock instructions?"
  end

  should "not be able to access the 2SV login page before logging in" do
    signout
    visit new_two_step_verification_session_path
    assert_equal "/users/sign_in", page.current_path
  end

  def assert_user_is_signed_in
    assert_response_contains "Your applications"
  end
end
