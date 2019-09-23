require_relative "../test_helper"

class UserLinkTest < ActionDispatch::IntegrationTest
  context "logged in as an admin" do
    setup do
      @admin = create(:admin_user, name: "Adam Adminson", email: "admin@example.com")
      visit new_user_session_path
      signin_with(@admin)
    end

    should "link to the current user's edit page" do
      click_on "Adam Adminson"
      assert page.has_content?("Edit “Adam Adminson”")
    end
  end
end
