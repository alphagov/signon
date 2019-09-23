require "test_helper"
require "support/password_helpers"

class EventLogPageIntegrationTest < ActionDispatch::IntegrationTest
  include PasswordHelpers

  setup do
    @admin = create(:admin_user, name: "Admin User")
    @user = create(:user, name: "Normal User")
  end

  test "users don't have permission to view account access log" do
    visit root_path
    signin_with(@user)

    click_link "Change your email or password"
    assert page.has_no_link? "Account access log"
  end

  test "admins have permission to view account access log" do
    @user.lock_access!
    visit root_path
    signin_with(@admin)
    visit edit_user_path(@user)
    click_on "Account access log"

    assert_account_access_log_page_content(@user)
  end

  test "superadmins have permission to view account access log" do
    @user.lock_access!
    super_nintendo_chalmers = create(:superadmin_user)

    visit root_path
    signin_with(super_nintendo_chalmers)
    visit edit_user_path(@user)
    click_on "Account access log"

    assert_account_access_log_page_content(@user)
  end

  test "super organisation admins have permission to view access logs of users belonging to their organisation" do
    super_org_admin = create(:super_org_admin)
    user = create(:user_in_organisation, organisation: super_org_admin.organisation)
    user.lock_access!

    visit root_path
    signin_with(super_org_admin)
    visit edit_user_path(user)
    click_on "Account access log"

    assert_account_access_log_page_content(user)
  end

  test "super organisation admins have permission to view access logs of users belonging to child organisations" do
    super_org_admin = create(:super_org_admin)
    child_org = create(:organisation, parent: super_org_admin.organisation)
    user = create(:user_in_organisation, organisation: child_org)
    user.lock_access!

    visit root_path
    signin_with(super_org_admin)
    visit edit_user_path(user)
    click_on "Account access log"

    assert_account_access_log_page_content(user)
  end

  test "super organisation admins don't have permission to view access logs of users belonging to another organisation" do
    super_org_admin = create(:super_org_admin)

    visit root_path
    signin_with(super_org_admin)
    visit event_logs_user_path(@user)

    assert page.has_content?("You do not have permission to perform this action")
  end

  test "organisation admins have permission to view access logs of users belonging to their organisation" do
    organisation_admin = create(:organisation_admin)
    user = create(:user_in_organisation, organisation: organisation_admin.organisation)
    user.lock_access!

    visit root_path
    signin_with(organisation_admin)
    visit edit_user_path(user)
    click_on "Account access log"

    assert_account_access_log_page_content(user)
  end

  test "organisation admins don't have permission to view access logs of users belonging to another organisation" do
    organisation_admin = create(:organisation_admin)

    visit root_path
    signin_with(organisation_admin)
    visit event_logs_user_path(@user)

    assert page.has_content?("You do not have permission to perform this action")
  end

  test "pages are paginated properly" do
    # 1 more than the number of items on the page to force pagination
    101.times { EventLog.record_event(@user, EventLog::SUCCESSFUL_LOGIN) }

    visit root_path

    signin_with(create(:superadmin_user))

    visit event_logs_user_path(@user)

    assert_text "Successful login"

    first("a[rel=next]").click

    assert_text "Successful login"
  end

  def assert_account_access_log_page_content(user)
    assert_text "Time"
    assert_text "Event"
    assert_text "account locked"
    assert_selector "a", text: user.name
  end
end
