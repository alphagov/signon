require "test_helper"

class AdminUserIndexTest < ActionDispatch::IntegrationTest
  context "logged in as an admin" do
    setup do
      User.delete_all
      admin = create(:admin_user, name: "Admin User", email: "admin@example.com")

      visit new_user_session_path
      signin_with(admin)
    end

    should "display the 2SV enrollment status for users" do
      create(:user)
      create(:two_step_enabled_user)

      visit "/users"

      within "table" do
        assert has_css?("td", text: "Enabled", count: 1)
        assert has_css?("td", text: "Not set up", count: 2)
      end
    end

    should "see when the user last logged in" do
      current_time = Time.zone.now
      Timecop.freeze(current_time)

      create(:user)
      create(:user, current_sign_in_at: current_time - 5.minutes)

      visit "/users"

      assert page.has_content?("Last sign-in")

      actual_last_sign_in_strings = page.all('table tr td:nth(3)').map(&:text).map(&:strip)[0..1]
      assert_equal ["5 minutes ago", "Not set"], actual_last_sign_in_strings

      Timecop.return
    end

    should "paginate through the users" do
      10.times { create(:user, name: "On the second page") }
      10.times { create(:user, name: "On the first page") }

      visit "/users"

      names_in_table = page.all('table tr td:first').map(&:text).map(&:strip).uniq
      assert names_in_table.all? { |name| name.start_with?("On the first page") }

      click_on "Next"

      names_in_table = page.all('table tr td:first').map(&:text).map(&:strip).uniq
      assert names_in_table.all? { |name| name.start_with?("On the second page") }

      click_on "Previous"

      names_in_table = page.all('table tr td:first').map(&:text).map(&:strip).uniq
      assert names_in_table.all? { |name| name.start_with?("On the first page") }
    end

    should "filter users by name and email" do
      create(:user, name: "Abbey", email: "abbey@example.com")
      create(:user, name: "Abbot", email: "mr_ab@example.com")
      create(:user, name: "Bert", email: "bbbert@example.com")
      create(:user, name: "Eddie", email: "eddie_bb@example.com")
      create(:user, name: "Aardvark", email: "aardvark@example.com")
      create(:user, name: "Ernie", email: "ernie@example.com")

      visit "/users"

      fill_in "Name or email", with: "bb"
      click_on "Search"

      assert page.has_content?("Abbey abbey@example.com")
      assert page.has_content?("Abbot mr_ab@example.com")
      assert page.has_content?("Bert bbbert@example.com")
      assert page.has_content?("Eddie eddie_bb@example.com")

      refute page.has_content?("Aardvark aardvark@example.com")
      refute page.has_content?("Ernie ernie@example.com")

      click_on "Users"

      assert page.has_content?("Users")
      assert page.has_content?("Aardvark aardvark@example.com")
    end

    should "filter users by role" do
      create(:user)
      create(:user)
      create(:admin_user)

      visit "/users"

      select "Normal", from: "role"
      click_on "Search"

      assert page.has_content?("2 users")

      select "Admin", from: "role"
      click_on "Search"

      assert page.has_content?("2 users")

      select "", from: "role"
      click_on "Search"

      assert page.has_content?("4 users")
    end

    should "filter users by status" do
      create(:suspended_user, name: "Suspended User", email: "suspenders@example.com")
      create(:user, name: "A non-suspended user", email: "other@example.com")

      visit "/users"

      assert page.has_content?("Suspended User")
      assert page.has_content?("A non-suspended user")

      select "suspended", from: "Status"
      click_on "Search"

      assert page.has_content?("Suspended User")
      refute page.has_content?("A non-suspended user")

      select "", from: "Status"
      click_on "Search"

      assert page.has_content?("Suspended User")
      assert page.has_content?("A non-suspended user")
    end

    should "filter users by organisation" do
      create(:user, name: "First Org User", organisation: create(:organisation, name: "Org 1"))
      create(:user, name: "Second Org User", organisation: create(:organisation, name: "Org 2"))

      visit "/users"

      select "Org 1", from: "Organisation"
      click_on "Search"

      assert page.has_content?("First Org User")
      assert page.has_content?("1 user")
    end

    should "filter users by 2SV status" do
      create(:user, name: "User Without 2SV")
      create(:two_step_enabled_user, name: "User With 2SV")

      visit "/users"
      select "Not set up", from: "Two-step status"
      click_on "Search"

      assert page.has_content?("User Without 2SV")
      refute page.has_content?("User With 2SV")

      select "Enabled", from: "Two-step status"
      click_on "Search"

      assert page.has_content?("User With 2SV")
      refute page.has_content?("User Without 2SV")
    end

    should "download users as CSV" do
      create(:user, name: "A certain user")
      create(:user, name: "Another user")

      visit "/users"

      fill_in "Name or email", with: "certain"
      click_on "Search"

      click_on "Export as CSV"

      assert has_content?("Name,Email,Role,Organisation,Sign-in count,Last sign-in,Created,Status,2SV Status")
      assert has_content?("A certain user")
      refute has_content?("Another user")
    end
  end
end
