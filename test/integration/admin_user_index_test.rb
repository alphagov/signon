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
        "Admin User <admin@example.com>",
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

      fill_in "Filter by name or email:", :with => "bb"
      click_on "Search"

      assert page.has_content?("Abbey <abbey@example.com>")
      assert page.has_content?("Abbot <mr_ab@example.com>")
      assert page.has_content?("Bert <bbbert@example.com>")
      assert page.has_content?("Eddie <eddie_bb@example.com>")

      assert ! page.has_content?("Aardvark <aardvark@example.com>")
      assert ! page.has_content?("Ernie <ernie@example.com>")

      click_on "Clear"

      assert page.has_content?("Users by initial letter:")
      assert page.has_content?("Aardvark <aardvark@example.com>")
    end
  end
end
