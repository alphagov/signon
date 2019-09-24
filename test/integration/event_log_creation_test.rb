require "test_helper"
require "support/password_helpers"

class EventLogCreationIntegrationTest < ActionDispatch::IntegrationTest
  include PasswordHelpers

  setup do
    @admin = create(:admin_user, name: "Admin User")
    @user = create(:user, name: "Normal User")
  end

  test "record successful login" do
    visit root_path
    signin_with(@user)

    assert_equal 1, @user.event_logs.count
    assert_equal EventLog::SUCCESSFUL_LOGIN, @user.event_logs.last.entry
  end

  context "recording unsuccessful login" do
    should "record unsuccessful login for a valid email" do
      visit root_path
      signin_with(email: @user.email, password: :incorrect)

      assert_equal 1, @user.event_logs.count
      assert_equal EventLog::UNSUCCESSFUL_LOGIN, @user.event_logs.last.entry
    end

    should "record an invalid email" do
      visit root_path
      signin_with(email: "nonexistent@example.com", password: "anything")

      assert_equal 1, EventLog.count
      assert_equal EventLog::NO_SUCH_ACCOUNT_LOGIN, EventLog.last.entry
    end

    should "raise an error when missing CSRF token" do
      assert_raises ActionController::InvalidAuthenticityToken do
        post "/users/sign_in", params: { "user" => { "email" => { "foo" => "bar" }, :password => "anything" } }
      end
    end
  end

  test "record password reset request" do
    visit root_path
    click_on "Forgot your password?"
    fill_in "Email address", with: @user.email
    click_on "Send email"

    assert_equal EventLog::PASSWORD_RESET_REQUEST, @user.event_logs.first.entry
  end

  test "record password reset page requested" do
    token_received_in_email = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    assert_equal EventLog::PASSWORD_RESET_LOADED, @user.event_logs.first.entry
  end

  test "record password reset page loaded but token expired" do
    token_received_in_email = Timecop.freeze((User.reset_password_within + 1.hour).ago) do
      @user.send_reset_password_instructions
    end
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    assert_equal EventLog::PASSWORD_RESET_LOADED_BUT_TOKEN_EXPIRED, @user.event_logs.first.entry
  end

  test "record password reset failed" do
    token_received_in_email = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    click_on "Save password"
    event_log = @user.event_logs.first

    assert_equal EventLog::PASSWORD_RESET_FAILURE, event_log.entry
    assert_match "Password can't be blank", event_log.trailing_message
  end

  test "record successful password reset from email" do
    token_received_in_email = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    new_password = "diagram donkey doodle"
    fill_in "New password", with: new_password
    fill_in "Confirm new password", with: new_password
    click_on "Save password"

    assert_includes @user.event_logs.map(&:entry), EventLog::SUCCESSFUL_PASSWORD_RESET
  end

  test "record successful password change" do
    new_password = "correct horse battery daffodil"
    visit root_path
    signin_with(@user)
    change_password(old: @user.password,
                    new: new_password,
                    new_confirmation: new_password)

    # multiple events are registered with the same time, order changes.
    assert_includes @user.event_logs.map(&:entry), EventLog::SUCCESSFUL_PASSWORD_CHANGE
  end

  test "record unsuccessful password change" do
    visit root_path
    signin_with(@user)
    change_password(old: @user.password,
                    new: @user.password,
                    new_confirmation: @user.password)

    # multiple events are registered with the same time, order changes.
    assert_includes @user.event_logs.map(&:entry), EventLog::UNSUCCESSFUL_PASSWORD_CHANGE
  end

  test "record account locked if password entered too many times" do
    visit root_path
    7.times { signin_with(email: @user.email, password: :incorrect) }

    # multiple events are registered with the same time, order changes.
    assert_includes @user.event_logs.map(&:entry), EventLog::ACCOUNT_LOCKED
  end

  test "record account unlocked along with event initiator" do
    @user.lock_access!

    visit root_path
    signin_with(@admin)
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on "Unlock"

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::MANUAL_ACCOUNT_UNLOCK.description + " by " + @admin.name)
  end

  test "record user suspension along with event initiator" do
    visit root_path
    signin_with(@admin)
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on @user.name.to_s
    click_on "Suspend user"
    check "Suspended?"
    fill_in "Reason for suspension", with: "Assaulting superior officer"
    click_on "Save"

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::ACCOUNT_SUSPENDED.description + " by " + @admin.name)
  end

  test "record suspended user's attempt to login with correct credentials" do
    @user.suspend("Assaulting superior officer")

    visit root_path
    signin_with(@user)

    assert_equal @user.event_logs.last.entry, EventLog::SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN
  end

  test "record user unsuspension along with event initiator" do
    @user.suspend("Gross negligence")

    visit root_path
    signin_with(@admin)
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on @user.name.to_s
    click_on "Unsuspend user"
    uncheck "Suspended?"
    click_on "Save"

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::ACCOUNT_UNSUSPENDED.description + " by " + @admin.name)
  end

  context "recording user's ip address" do
    should "record user's IPv4 address for successful login" do
      page.driver.options[:headers] = { "REMOTE_ADDR" => "1.2.3.4" }
      visit root_path
      signin_with(@user)

      ip_address = @user.event_logs.first.ip_address_string
      assert_equal "1.2.3.4", ip_address
    end

    should "record user's IPv4 address for unsuccessful login" do
      page.driver.options[:headers] = { "REMOTE_ADDR" => "4.5.6.7" }
      visit root_path
      signin_with(email: @user.email, password: :incorrect)

      ip_address = @user.event_logs.last.ip_address_string
      assert_equal "4.5.6.7", ip_address
    end

    should "record user's IPv6 address" do
      page.driver.options[:headers] = { "REMOTE_ADDR" => "2001:0db8:0000:0000:0008:0800:200c:417a" }
      visit root_path
      signin_with(@user)

      ip_address = @user.event_logs.first.ip_address_string
      assert_equal "2001:db8::8:800:200c:417a", ip_address
    end
  end

  test "record who the account was created by" do
    visit root_path
    signin_with(@admin)
    visit users_path
    click_on "Create user"
    fill_in "Name", with: "New User"
    fill_in "Email", with: "test@test.com"
    click_on "Create user and send email"

    event_log = User.last.event_logs.first
    assert_equal @admin, event_log.initiator
    assert_equal EventLog::ACCOUNT_INVITED, event_log.entry
  end
end
