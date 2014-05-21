require 'test_helper'
require 'helpers/passphrase_support'

class EventLogTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  setup do
    @admin = create(:user, role: "admin")
    @user = create(:user, name: "Jim Holden")
  end

  test "record successful login" do
    visit root_path
    signin @user

    assert_equal EventLog.for(@user).last.event, EventLog::SUCCESSFUL_LOGIN
  end

  test "record unsuccessful login" do
    visit root_path
    signin(email: @user.email, password: :incorrect)

    assert_equal EventLog.for(@user).last.event, EventLog::UNSUCCESSFUL_LOGIN
  end

  test "record passphrase reset request" do
    visit root_path
    click_on "Forgot your passphrase?"
    fill_in "Email", with: @user.email
    click_on "Send me passphrase reset instructions"

    log = EventLog.for(@user).first
    assert_equal log.event, EventLog::PASSPHRASE_RESET_REQUEST
  end

  test "record successful passphrase change" do
    new_password = "correct horse battery daffodil"
    visit root_path
    signin @user
    change_password(old: @user.password,
                    new: new_password,
                    new_confirmation: new_password)

    assert_equal EventLog.for(@user).last.event, EventLog::SUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record unsuccessful passphrase change" do
    visit root_path
    signin @user
    change_password(old: @user.password,
                    new: @user.password,
                    new_confirmation: @user.password)

    assert_equal EventLog.for(@user).last.event, EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record account locked if password entered too many times" do
    visit root_path
    7.times { signin(email: @user.email, password: :incorrect) }

    # Account locked event appears before the login attempt that triggered it
    assert_equal EventLog.for(@user)[-2].event, EventLog::ACCOUNT_LOCKED
  end

  test "record account unlocked" do
    @user.lock_access!

    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_on 'Unlock'

    assert_equal EventLog.for(@user).last.event, EventLog::AUTOMATIC_ACCOUNT_UNLOCK
  end

  test "record user suspension" do
    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_on "#{@user.name} <#{@user.email}>"
    click_on 'Suspend this user'
    check 'Suspended?'
    fill_in 'Reason for suspension', with: 'righteousness'
    click_on 'Save'

    assert_equal EventLog.for(@user).last.event, EventLog::ACCOUNT_SUSPENDED
  end

  test "record user unsuspension" do
    user = create(:user, name: 'Julie Mao',
                         suspended_at: 5.days.ago,
                         reason_for_suspension: 'Gross negligence')

    visit root_path
    signin @admin
    first_letter_of_name = user.name[0]
    visit admin_users_path(letter: first_letter_of_name)
    click_on "#{user.name} <#{user.email}>"
    click_on 'Unsuspend this user'
    uncheck 'Suspended?'
    click_on 'Save'

    assert_equal EventLog.for(user).last.event, EventLog::ACCOUNT_UNSUSPENDED
  end

  test "record password expiration" do
    @user.password_changed_at = 100.days.ago; @user.save

    visit root_path
    signin @user

    assert_equal EventLog.for(@user).last.event, EventLog::PASSPHRASE_EXPIRED
  end
end
