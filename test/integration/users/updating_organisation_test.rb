require "test_helper"

class Users::UpdatingOrganisationTest < ActionDispatch::IntegrationTest
  should "display read-only values for users who aren't GOVUK Admins" do
    organisation = create(:organisation, name: "Department for Viability")
    user = create(:user, organisation:)
    non_govuk_admin_user = create(:super_organisation_admin_user, organisation:)

    visit new_user_session_path
    signin_with non_govuk_admin_user

    visit edit_user_path(user)

    assert has_text? "Department for Viability"
    assert_no_selector "a", text: "Change Organisation"
  end

  should "allow GOV.UK admin users to change their organisation" do
    current_organisation = create(:organisation, name: "Judiciary")
    user = create(:user, organisation: current_organisation)
    admin_user = create(:admin_user)

    create(:organisation, name: "Postage")

    visit new_user_session_path
    signin_with admin_user

    visit edit_user_organisation_path(user)

    select "Postage", from: "Organisation"
    click_button "Change organisation"

    assert_current_url edit_user_path(user)
    assert page.has_text? "Updated user #{user.email} successfully"
    assert_equal "Postage", user.reload.organisation_name
  end
end
