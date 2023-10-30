require "test_helper"

class AccountRolesTest < ActionDispatch::IntegrationTest
  context "#show" do
    should "display read-only values for users who aren't GOVUK Admins" do
      non_govuk_admin_user = create(:super_organisation_admin_user)

      visit new_user_session_path
      signin_with non_govuk_admin_user

      visit edit_account_role_path

      assert has_text? "Super organisation admin"
    end

    should "allow Superadmin users to change their role" do
      user = FactoryBot.create(:superadmin_user)

      visit new_user_session_path
      signin_with user

      visit edit_account_role_path

      select "Normal", from: "Role"
      click_button "Change role"

      assert_current_url account_path
      assert page.has_text? "Your role is now Normal"

      visit edit_account_role_path

      assert has_text? "Normal"
    end
  end
end
