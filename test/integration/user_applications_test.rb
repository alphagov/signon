require "test_helper"

class UserApplicationsTest < ActionDispatch::IntegrationTest
  should "allow admins to grant users access to apps" do
    user = create(:user, name: "user-name")
    create(:application, name: "app-name")

    admin_user = create(:admin_user)
    visit new_user_session_path
    signin_with admin_user

    visit user_applications_path(user)

    heading = find("h2", text: "Apps user-name does not have access to")
    table = find("table[aria-labelledby='#{heading['id']}']")
    assert table.has_content?("app-name")

    click_on "Grant access to app-name"

    table = find("table caption[text()='Apps user-name has access to']").ancestor("table")
    assert table.has_content?("app-name")
  end
end
