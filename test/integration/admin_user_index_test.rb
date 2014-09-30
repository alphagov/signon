require_relative "../test_helper"

class AdminUserIndexTest < ActionDispatch::IntegrationTest

  context "logged in as an admin" do
    setup do
      current_time = Time.zone.now
      Timecop.freeze(current_time)

      @admin = create(:admin_user, :name => "Admin User", :email => "admin@example.com")
      visit new_user_session_path
      signin(@admin)

      create(:user, :name => "Aardvark", :email => "aardvark@example.com", :current_sign_in_at => current_time - 5.minutes)
      create(:user, :name => "Abbey", :email => "abbey@example.com")
      create(:user, :name => "Abbot", :email => "mr_ab@example.com")
      create(:user, :name => "Bert", :email => "bbbert@example.com")
      create(:user, :name => "Ed", :email => "ed@example.com")
      create(:user, :name => "Eddie", :email => "eddie_bb@example.com")
      create(:user, :name => "Ernie", :email => "ernie@example.com")
    end

    teardown do
      Timecop.return
    end

    should "see when the user last logged in" do
      visit "/admin/users"

      assert page.has_content?("Last sign-in")

      actual_last_sign_in_strings = page.all('table tr td.last-sign-in').map(&:text).map(&:strip)[0..1]
      assert_equal ["5 minutes ago", "never signed in"], actual_last_sign_in_strings
    end

    should "see list of users paginated alphabetically" do
      visit "/admin/users"

      assert page.has_content?("User accounts")

      expected = [
        "Aardvark <aardvark@example.com>",
        "Abbey <abbey@example.com>",
        "Abbot <mr_ab@example.com>",
      ]
      actual = page.all('table tr td.email').map(&:text).map(&:strip)
      assert_equal expected, actual

      within first('.pagination') do
        click_on "E"
      end

      expected = [
        "Ed <ed@example.com>",
        "Eddie <eddie_bb@example.com>",
        "Ernie <ernie@example.com>",
      ]
      actual = page.all('table tr td.email').map(&:text).map(&:strip)
      assert_equal expected, actual
    end

    should "be able to filter users" do
      visit "/admin/users"

      fill_in "Name or email", :with => "bb"
      click_on "Search"

      assert page.has_content?("Abbey <abbey@example.com>")
      assert page.has_content?("Abbot <mr_ab@example.com>")
      assert page.has_content?("Bert <bbbert@example.com>")
      assert page.has_content?("Eddie <eddie_bb@example.com>")

      assert ! page.has_content?("Aardvark <aardvark@example.com>")
      assert ! page.has_content?("Ernie <ernie@example.com>")

      click_on "Users"

      assert page.has_content?("Users by initial")
      assert page.has_content?("Aardvark <aardvark@example.com>")
    end

    should "filter users by role" do
      visit "/admin/users"

      role_not_present("Admin")

      select_role("Normal")

      assert_equal User.with_role(:normal).count, page.all('table tbody tr').count
      assert ! page.has_content?("Admin User <admin@example.com>")
      User.with_role(:normal).each do |normal_user|
        assert page.has_content?(normal_user.email)
      end

      select_role("All roles")

      %w(Aardvark Abbot Abbey Admin).each do |user_name|
        assert page.has_content?(user_name)
      end
    end

    def select_role(role_name)
      click_on "filter-by-role-menu"
      within ".dropdown-menu" do
        click_on role_name
      end
    end

    def role_not_present(role_name)
      click_on "filter-by-role-menu"
      within ".dropdown-menu" do
        page.has_no_content? role_name
      end
    end
  end
end
