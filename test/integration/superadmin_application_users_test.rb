require "test_helper"

class SuperAdminApplicationUsersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  context "logged in as an superadmin" do
    setup do
      @application = create(:application)

      visit new_user_session_path
      signin_with(create(:superadmin_user))
    end

    should "see all the users with access" do
      click_link "Apps"

      # Create a user that's authorized to use our app
      user = create(:user, name: "My Test User")
      user.grant_application_permission(@application, "signin")

      click_link @application.name

      click_link "Users with access"

      assert page.has_content?(user.name)
    end
  end
end
