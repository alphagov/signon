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
      create(:user, name: "Ernie", email: "ernie@example.com", organisation: org2)
      create(:suspended_user, name: "Suspended McFee", email: "suspenders@example.com")
    end

    teardown do
      Timecop.return
    end

    should "display the 2SV enrollment status for users" do
      visit "/users"

      within "table" do
        assert has_css?("td", text: "Enabled", count: 1)
        assert has_css?("td", text: "Not set up", count: 3)
      end
    end

    should "see when the user last logged in" do
      visit "/users"

      assert page.has_content?("Last sign-in")

      actual_last_sign_in_strings = page.all("table tr td.last-sign-in").map(&:text).map(&:strip)[0..1]
      assert_equal ["5 minutes ago", "never signed in"], actual_last_sign_in_strings
    end

    should "see list of users paginated alphabetically" do
      visit "/users"

      assert page.has_content?("Users")

      expected = [
        "Aardvark aardvark@example.com",
        "Abbey abbey@example.com",
        "Abbot mr_ab@example.com",
        "Admin User admin@example.com",
      ]
      actual = page.all("table tr td.email").map(&:text).map(&:strip)
      assert_equal expected, actual

      within first(".pagination") do
        click_on "E"
      end

      expected = [
        "Ed ed@example.com",
        "Eddie eddie_bb@example.com",
        "Ernie ernie@example.com",
      ]
      actual = page.all("table tr td.email").map(&:text).map(&:strip)
      assert_equal expected, actual
    end

    should "be able to filter users" do
      visit "/users"

      fill_in "Name or email", with: "bb"
      click_on "Search"

      assert page.has_content?("Abbey abbey@example.com")
      assert page.has_content?("Abbot mr_ab@example.com")
      assert page.has_content?("Bert bbbert@example.com")
      assert page.has_content?("Eddie eddie_bb@example.com")

      assert_not page.has_content?("Aardvark aardvark@example.com")
      assert_not page.has_content?("Ernie ernie@example.com")

      click_on "Users"

      assert page.has_content?("Users by initial")
      assert page.has_content?("Aardvark aardvark@example.com")
    end

    should "filter users by role" do
      visit "/users"

      assert_role_not_present("Superadmin")

      select_role("Normal")

      assert_equal User.with_role(:normal).count, page.all("table tbody tr").count
      assert_not page.has_content?("Admin User admin@example.com")
      User.with_role(:normal).each do |normal_user|
        assert page.has_content?(normal_user.email)
      end

      select_role("All Roles")

      %w[Aardvark Abbot Abbey Admin].each do |user_name|
        assert page.has_content?(user_name)
      end
    end

    should "filter users by permission" do
      uap = create(:user_application_permission, user: User.find_by(name: "Ernie"))
      visit "/users"

      select_permission("#{uap.application.name} #{uap.supported_permission.name}")

      assert_equal 1, page.all("table tbody tr").count
      within ".table" do
        assert page.has_content?("Ernie")
        (User.pluck(:name) - %w[Ernie]).each do |name|
          assert_not page.has_content?(name)
        end
      end

      select_permission("All Permissions")

      %w[Aardvark Abbot Abbey Admin].each do |user_name|
        assert page.has_content?(user_name)
      end
    end

    should "filter users by status" do
      visit "/users"

      select_status("Suspended")

      assert_equal 1, page.all("table tbody tr").count
      assert_not page.has_content?("Aardvark")
      assert page.has_content?("Suspended McFee")

      select_status("All Statuses")

      %w[Aardvark Abbot Abbey Admin Suspended].each do |user_name|
        assert page.has_content?(user_name)
      end
    end

    should "filter users by organisation" do
      visit "/users"

      select_organisation("Org 1")
      assert_equal 1, page.all("table tbody tr").count
      assert_not page.has_content?("Aardvark")
      assert page.has_content?("Ed")

      select_organisation("All Organisations")

      %w[Aardvark Abbot Abbey Admin Suspended].each do |user_name|
        assert page.has_content?(user_name)
      end
    end

    should "filter users by 2SV status" do
      visit "/users"
      total_enabled = 1
      total_disabled = 8

      within ".filter-by-two_step_status-menu .dropdown-menu" do
        click_on "Enabled"
      end

      assert has_css?("td", text: "Enabled", count: total_enabled)
      assert has_no_css?("td", text: "Not set up")

      within ".filter-by-two_step_status-menu .dropdown-menu" do
        click_on "Not set up"
      end

      assert has_no_css?("td", text: "Enabled")
      assert has_css?("td", text: "Not set up", count: total_disabled)
    end
  end

  def select_organisation(organisation_name)
    within ".filter-by-organisation-menu .dropdown-menu" do
      click_on organisation_name
    end
  end

  def select_status(status_name)
    within ".filter-by-status-menu .dropdown-menu" do
      click_on status_name
    end
  end

  def assert_role_not_present(role_name)
    within ".filter-by-role-menu" do
      click_on "Role", match: :prefer_exact
      within ".dropdown-menu" do
        assert page.has_no_content? role_name
      end
    end
  end

  def select_role(role_name)
    within ".filter-by-role-menu" do
      click_on "Role", match: :prefer_exact
      within ".dropdown-menu" do
        click_on role_name
      end
    end
  end

  def select_permission(permission_name)
    within ".filter-by-permission-menu" do
      click_on permission_name
    end
  end
end
