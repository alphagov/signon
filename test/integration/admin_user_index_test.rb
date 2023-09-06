require "test_helper"

class AdminUserIndexTest < ActionDispatch::IntegrationTest
  context "logged in as an admin" do
    setup do
      current_time = Time.zone.now
      Timecop.freeze(current_time)

      @admin = create(:admin_user, name: "Admin User", email: "admin@example.com")
      visit new_user_session_path
      signin_with(@admin)

      org1 = create(:organisation, name: "Org 1")
      org2 = create(:organisation, name: "Org 2")

      create(:user, name: "Aardvark", email: "aardvark@example.com", current_sign_in_at: current_time - 5.minutes)
      create(:two_step_enabled_user, name: "Abbey", email: "abbey@example.com")
      create(:user, name: "Abbot", email: "mr_ab@example.com")
      create(:user, name: "Bert", email: "bbbert@example.com")
      create(:user, name: "Ed", email: "ed@example.com", organisation: org1)
      create(:user, name: "Eddie", email: "eddie_bb@example.com")
      create(:two_step_exempted_user, name: "Ernie", email: "ernie@example.com", organisation: org2)
      create(:suspended_user, name: "Suspended McFee", email: "suspenders@example.com")
    end

    teardown do
      Timecop.return
    end

    should "display the 2SV enrollment status for users" do
      visit "/users"

      within "table" do
        assert has_css?("td", text: "Enabled", count: 1)
        assert has_css?("td", text: "Not set up", count: 7)
      end
    end

    should "see when the user last logged in" do
      visit "/users"

      assert page.has_content?("Last sign-in")

      actual_last_sign_in_strings = page.all("table tr td.last-sign-in").map(&:text).map(&:strip)[0..1]
      assert_equal ["5 minutes ago", "never signed in"], actual_last_sign_in_strings
    end
  end
end
