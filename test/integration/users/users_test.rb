require "test_helper"

class UsersTest < ActionDispatch::IntegrationTest
  context "logged in as an admin" do
    setup do
      use_javascript_driver

      current_time = Time.current
      Timecop.freeze(current_time)

      @admin = create(:admin_user, name: "Admin User", email: "admin@example.com")
      visit new_user_session_path
      signin_with(@admin)

      org1 = create(:organisation, name: "Org 1")
      org2 = create(:organisation, name: "Org 2")

      @aardvark = create(:user, name: "Aardvark", email: "aardvark@example.com", current_sign_in_at: current_time - 5.minutes)
      @abbey = create(:two_step_enabled_user, name: "Abbey", email: "abbey@example.com")
      @abbot = create(:user, name: "Abbot", email: "mr_ab@example.com")
      @bert = create(:user, name: "Bert", email: "bbbert@example.com")
      @ed = create(:user, name: "Ed", email: "ed@example.com", organisation: org1)
      @eddie = create(:user, name: "Eddie", email: "eddie_bb@example.com")
      @ernie = create(:two_step_exempted_user, name: "Ernie", email: "ernie@example.com", organisation: org2)
      @suspended_mcfee = create(:suspended_user, name: "Suspended McFee", email: "suspenders@example.com")

      application = create(:application, name: "App name")
      create(:supported_permission, application:, name: "App permission")
      @aardvark.grant_application_signin_permission(application)
      @bert.grant_application_permission(application, "App permission")

      visit "/users"
    end

    teardown do
      Timecop.return
    end

    should "display the 2SV enrollment status for users" do
      within "table" do
        assert has_css?("td", text: "Enabled", count: 1)
        assert has_css?("td", text: "Not set up", count: 7)
      end
    end

    should "list all users" do
      assert_results @admin, @aardvark, @abbey, @abbot, @bert, @ed, @eddie, @ernie, @suspended_mcfee
    end

    should "filter users by search string" do
      fill_in "Search", with: "bb"
      click_on "Search"

      assert_results @abbey, @abbot, @bert, @eddie
    end

    should "filter users by status" do
      check "Suspended", allow_label_click: true

      assert_results @suspended_mcfee
    end

    should "filter users by 2sv status" do
      click_on "2SV Status"

      check "Exempted", allow_label_click: true
      assert_results @ernie

      check "Enable", allow_label_click: true
      assert_results @ernie, @abbey
    end

    should "filter users by role" do
      click_on "Role"

      check "Admin", allow_label_click: true
      assert_results @admin
    end

    should "filter users by organisation" do
      click_on "Organisation"

      check "Org 1", allow_label_click: true
      assert_results @ed

      check "Org 2", allow_label_click: true
      assert_results @ed, @ernie
    end

    should "filter users by permission" do
      click_on "Permissions"

      check "App name signin", allow_label_click: true
      assert_results @aardvark

      check "App name App permission", allow_label_click: true
      assert_results @aardvark, @bert
    end
  end

private

  def assert_results(*users)
    expected_table_caption = [users.count, "user".pluralize(users.count)].join(" ")

    table = find("table caption", text: expected_table_caption).ancestor(:table)
    assert table.has_css?("tbody tr", count: users.count)

    users.each do |user|
      assert table.has_content?(user.name)
    end
  end
end
