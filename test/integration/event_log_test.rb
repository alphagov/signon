require 'test_helper'
require 'helpers/passphrase_support'

class EventLogTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  setup do
    @admin = create(:admin_user, name: "Admin User")
    @user = create(:user, name: "Normal User")
  end

  test "record successful login" do
    visit root_path
    signin @user

    assert_equal 1, @user.event_logs.count
    assert_equal EventLog::SUCCESSFUL_LOGIN, @user.event_logs.last.event
  end

  context "recording unsuccessful login" do
    should "record unsuccessful login for a valid email" do
      visit root_path
      signin(email: @user.email, password: :incorrect)

      assert_equal 1, @user.event_logs.count
      assert_equal EventLog::UNSUCCESSFUL_LOGIN, @user.event_logs.last.event
    end

    should "log nothing for an invalid email" do
      visit root_path
      signin(email: "nonexistent@example.com", password: "anything")

      assert_equal 0, EventLog.count
    end

    should "not blow up if not given a string for the email" do
      # Assert we don't blow up when looking up the attempted user
      # when people have been messing with the posted params.
      post "/users/sign_in", "user" => {"email" => {"foo" => "bar"}, :password => "anything"}

      assert response.success?
    end
  end

  test "record passphrase reset request" do
    visit root_path
    click_on "Forgot your passphrase?"
    fill_in "Email", with: @user.email
    click_on "Send me passphrase reset instructions"

    assert_equal EventLog::PASSPHRASE_RESET_REQUEST, @user.event_logs.first.event
  end

  test "record successful passphrase change" do
    new_password = "correct horse battery daffodil"
    visit root_path
    signin @user
    change_password(old: @user.password,
                    new: new_password,
                    new_confirmation: new_password)

    # multiple events are registered with the same time, order changes.
    assert_include @user.event_logs.map(&:event), EventLog::SUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record unsuccessful passphrase change" do
    visit root_path
    signin @user
    change_password(old: @user.password,
                    new: @user.password,
                    new_confirmation: @user.password)

    # multiple events are registered with the same time, order changes.
    assert_include @user.event_logs.map(&:event), EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE
  end

  test "record account locked if password entered too many times" do
    visit root_path
    7.times { signin(email: @user.email, password: :incorrect) }

    # multiple events are registered with the same time, order changes.
    assert_include @user.event_logs.map(&:event), EventLog::ACCOUNT_LOCKED
  end

  test "record account unlocked along with event initiator" do
    @user.lock_access!

    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on 'Unlock'

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::MANUAL_ACCOUNT_UNLOCK + ' by ' + @admin.name)
  end

  test "record user suspension along with event initiator" do
    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on "#{@user.name}"
    click_on 'Suspend user'
    check 'Suspended?'
    fill_in 'Reason for suspension', with: 'Assaulting superior officer'
    click_on 'Save'

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::ACCOUNT_SUSPENDED + ' by ' + @admin.name)
  end

  test "record suspended user's attempt to login with correct credentials" do
    @user.suspend('Assaulting superior officer')

    visit root_path
    signin @user

    assert_equal @user.event_logs.last.event, EventLog::SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN
  end

  test "record user unsuspension along with event initiator" do
    @user.suspend('Gross negligence')

    visit root_path
    signin @admin
    first_letter_of_name = @user.name[0]
    visit users_path(letter: first_letter_of_name)
    click_on "#{@user.name}"
    click_on 'Unsuspend user'
    uncheck 'Suspended?'
    click_on 'Save'

    visit event_logs_user_path(@user)
    assert page.has_content?(EventLog::ACCOUNT_UNSUSPENDED + ' by ' + @admin.name)
  end

  test "record password expiration" do
    @user.password_changed_at = 100.days.ago; @user.save!

    visit root_path
    signin @user

    assert_include @user.event_logs.map(&:event), EventLog::PASSPHRASE_EXPIRED
  end

  test "users don't have permission to view account access log" do
    visit root_path
    signin @user

    click_link "Change your email or passphrase"
    assert page.has_no_link? 'Account access log'
  end

  test "admins have permission to view account access log" do
    @user.lock_access!
    visit root_path
    signin @admin
    visit edit_user_path(@user)
    click_on 'Account access log'

    assert_account_access_log_page_content(@user)
  end

  test "superadmins have permission to view account access log" do
    @user.lock_access!
    super_nintendo_chalmers = create(:superadmin_user)

    visit root_path
    signin super_nintendo_chalmers
    visit edit_user_path(@user)
    click_on 'Account access log'

    assert_account_access_log_page_content(@user)
  end

  test "organisation admins have permission to view access logs of users belonging to their organisation" do
    admin = create(:organisation_admin)
    user = create(:user_in_organisation, organisation: admin.organisation)
    user.lock_access!

    visit root_path
    signin admin
    visit edit_user_path(user)
    click_on 'Account access log'

    assert_account_access_log_page_content(user)
  end

  test "organisation admins don't have permission to view access logs of users belonging to another organisation" do
    admin = create(:organisation_admin)

    visit root_path
    signin admin
    visit event_logs_user_path(@user)

    assert page.has_content?("You do not have permission to perform this action")
  end

  def assert_account_access_log_page_content(user)
    assert page.has_content?('Time')
    assert page.has_content?('Event')
    assert page.has_content?('Account locked')
    assert page.has_link?("#{user.name}")
  end
end
