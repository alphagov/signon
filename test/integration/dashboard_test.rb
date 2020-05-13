require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  should "notify the user if they've not been assigned any applications" do
    app = create(:application, name: "MyApp", show_on_dashboard: false)
    user = create(:user, with_signin_permissions_for: [app])

    visit root_path
    signin_with(user)

    assert_response_contains("Your applications")
    assert_response_contains("You haven’t been assigned to any applications yet")
  end

  should "show the user's assigned applications" do
    app = create(:application, name: "MyApp")
    user = create(:user, with_signin_permissions_for: [app])

    visit root_path
    signin_with(user)

    assert_response_contains(app.description)
    assert page.has_css?("a[href='#{app.home_uri}']")
  end

  context "when the user has enrolled in 2SV" do
    should "display the 'change' link" do
      user = create(:two_step_enabled_user)
      visit root_path
      signin_with(user)

      assert has_link?("Change your 2-step verification phone")
    end
  end

  context "when the user is not enrolled in 2SV" do
    should "display the 'set up' link" do
      user = create(:user)
      visit root_path
      signin_with(user)

      assert_response_contains("Make your account more secure")
      assert has_link?("Set up 2-step verification")
    end
  end
end
