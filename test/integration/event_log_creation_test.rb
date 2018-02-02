require 'test_helper'
require 'helpers/passphrase_support'

class EventLogCreationIntegrationTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

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

    should "log nothing for an invalid email" do
      visit root_path
      signin_with(email: "nonexistent@example.com", password: "anything")

      assert_equal 0, EventLog.count
    end

    should "not blow up if not given a string for the email" do
      # Assert we don't blow up when looking up the attempted user
      # when people have been messing with the posted params.
      post "/users/sign_in", params: { "user" => { "email" => { "foo" => "bar" }, :password => "anything" } }

      assert response.success?
    end
  end

  test "record passphrase reset request" do
    visit root_path
    click_on "Forgot your passphrase?"
    fill_in "Email", with: @user.email
    click_on "Send me passphrase reset instructions"

    assert_equal EventLog::PASSPHRASE_RESET_REQUEST, @user.event_logs.first.entry
  end

  test "record passphrase reset page requested" do
    token_received_in_email = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    assert_equal EventLog::PASSPHRASE_RESET_LOADED, @user.event_logs.first.entry
  end

  test "record passphrase reset page loaded but token expired" do
    token_received_in_email = Timecop.freeze((User.reset_password_within + 1.hour).ago) do
      @user.send_reset_password_instructions
    end
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    assert_equal EventLog::PASSPHRASE_RESET_LOADED_BUT_TOKEN_EXPIRED, @user.event_logs.first.entry
  end

  test "record passphrase reset failed" do
    token_received_in_email = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    click_on "Change passphrase"
    event_log = @user.event_logs.first

    assert_equal EventLog::PASSPHRASE_RESET_FAILURE, event_log.entry
    assert_match "Passphrase can't be blank", event_log.trailing_message
  end

  test "record successful passphrase reset from email" do
    token_received_in_email = @user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token_received_in_email)

    new_passphrase = "diagram donkey doodle"
    fill_in "New passphrase", with: new_passphrase
    fill_in "Confirm new passphrase", with: new_passphrase
    click_on "Change passphrase"

    assert_includes @user.event_logs.map(&:entry), EventLog::SUCCESSFUL_PASSPHRASE_RESET
  end

  test "record successful passphrase change" do
    new_password = "correct horse battery daffodil"
    visit root_path
    signin_with(@user)
    change_password(old: @user.password,
                    new: new_password,
                    new_confirmation: new_password)

    # multiple events are registered with the same time, order changes.
    assert_includes @user.event_logs.map(&:entry), EventLog::SUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record unsuccessful passphrase change" do
    visit root_path
    signin_with(@user)
    change_password(old: @user.password,
                    new: @user.password,
                    new_confirmation: @user.password)

    # multiple events are registered with the same time, order changes.
    assert_includes @user.event_logs.map(&:entry), EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE
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
    click_on 'Unlock'

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::MANUAL_ACCOUNT_UNLOCK.description + ' by ' + @admin.name)
  end

  test "record user suspension along with event initiator" do
    visit root_path
    signin_with(@admin)
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on "#{@user.name}"
    click_on 'Suspend user'
    check 'Suspended?'
    fill_in 'Reason for suspension', with: 'Assaulting superior officer'
    click_on 'Save'

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::ACCOUNT_SUSPENDED.description + ' by ' + @admin.name)
  end

  test "record suspended user's attempt to login with correct credentials" do
    @user.suspend('Assaulting superior officer')

    visit root_path
    signin_with(@user)

    assert_equal @user.event_logs.last.entry, EventLog::SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN
  end

  test "record user unsuspension along with event initiator" do
    @user.suspend('Gross negligence')

    visit root_path
    signin_with(@admin)
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on "#{@user.name}"
    click_on 'Unsuspend user'
    uncheck 'Suspended?'
    click_on 'Save'

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::ACCOUNT_UNSUSPENDED.description + ' by ' + @admin.name)
  end

  test "record password expiration" do
    @user.password_changed_at = 100.days.ago; @user.save!

    visit root_path
    signin_with(@user)

    assert_includes @user.event_logs.map(&:entry), EventLog::PASSPHRASE_EXPIRED
  end

  context "recording user's ip address" do
    should "record user's ip address on login" do
      page.driver.options[:headers] = { 'REMOTE_ADDR' => '1.2.3.4' }
      visit root_path
      signin_with(@user)

      ip_address = @user.event_logs.first.ip_address_string
      assert_equal '1.2.3.4', ip_address
    end

    should "call alert error service for ipv6 addresses" do
      page.driver.options[:headers] = { 'REMOTE_ADDR' => '2001:0db8:0000:0000:0008:0800:200c:417a' }
      GovukError.expects(:notify)
      visit root_path
      signin_with(@user)

      ip_address = @user.event_logs.first.ip_address
      assert_equal nil, ip_address
    end
  end

  test "record who the account was created by" do
    visit root_path
    signin_with(@admin)
    visit users_path
    click_on "Create user"
    fill_in 'Name', with: 'New User'
    fill_in 'Email', with: 'test@test.com'
    click_on "Create user and send email"

    event_log = User.last.event_logs.first
    assert_equal @admin, event_log.initiator
    assert_equal EventLog::ACCOUNT_INVITED, event_log.entry
  end
end
