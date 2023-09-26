require "test_helper"

class AccountRoleOrganisationsTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "display read-only values for users who aren't GOVUK Admins" do
      organisation = create(:organisation, name: "Department for Viability")
      non_govuk_admin_user = create(:super_organisation_admin_user, organisation:)

      visit new_user_session_path
      signin_with non_govuk_admin_user

      visit account_role_organisation_path

      within "section", text: "Your role" do
        assert has_text? "Super organisation admin"
      end

      within "section", text: "Your organisation" do
        assert has_text? "Department for Viability"
      end
    end

    should "allow Superadmin users to change their role" do
      user = FactoryBot.create(:superadmin_user)

      visit new_user_session_path
      signin_with user

      visit account_role_organisation_path

      select "Normal", from: "Role"
      click_button "Change role"

      assert_current_url account_path
      assert page.has_text? "Your role is now Normal"

      visit account_role_organisation_path

      within "section", text: "Your role" do
        assert has_text? "Normal"
      end
    end

    should "allow GOVUK Admin users to change their organisation" do
      current_organisation = create(:organisation, name: "Judiciary")
      user = FactoryBot.create(:admin_user, organisation: current_organisation)

      create(:organisation, name: "Postage")

      visit new_user_session_path
      signin_with user

      visit account_role_organisation_path

      select "Postage", from: "Organisation"
      click_button "Change organisation"

      assert_current_url account_path
      assert page.has_text? "Your organisation is now Postage"

      visit account_role_organisation_path

      assert page.has_select? "Organisation", selected: "Postage"
    end
  end
end
