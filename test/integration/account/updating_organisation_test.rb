require "test_helper"

class Account::UpdatingOrganisationTest < ActionDispatch::IntegrationTest
  should "display read-only values for users who aren't GOVUK Admins" do
    organisation = create(:organisation, name: "Department for Viability")
    non_govuk_admin_user = create(:super_organisation_admin_user, organisation:)

    visit new_user_session_path
    signin_with non_govuk_admin_user

    visit edit_account_organisation_path

    assert has_text? "Department for Viability"
    assert_no_selector "select"
  end

  should "allow GOV.UK admin users to change their organisation" do
    current_organisation = create(:organisation, name: "Judiciary")
    user = create(:admin_user, organisation: current_organisation)

    create(:organisation, name: "Postage")

    visit new_user_session_path
    signin_with user

    visit edit_account_organisation_path

    select "Postage", from: "Organisation"
    click_button "Change organisation"

    assert_current_url account_path
    assert page.has_text? "Your organisation is now Postage"
    assert_equal "Postage", user.reload.organisation_name
  end
end
