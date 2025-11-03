require_relative "../test_helper"

class ManageApiUsersTest < ActionDispatch::IntegrationTest
  context "as Superadmin" do
    setup do
      @application = create(:application, with_non_delegated_supported_permissions: %w[write])

      @superadmin = create(:superadmin_user)
      visit new_user_session_path
      signin_with(@superadmin)

      @api_user = create(:api_user, with_permissions: { @application => %w[write] })
      create(:access_token, resource_owner_id: @api_user.id, application_id: @application.id)

      click_link "APIs"
    end

    should "be able to view a list of API users alongwith their authorised applications" do
      assert page.has_selector?("td", text: @api_user.name)
      assert page.has_selector?("td", text: @api_user.email)

      assert page.has_selector?("td", text: @application.name)
      assert page.has_selector?("td:last-child", text: "Active") # status
    end

    should "be able to create and edit an API user" do
      click_link "Create API user"

      fill_in "Name", with: "Content Store Application"
      fill_in "Email", with: "content.store@gov.uk"
      click_button "Create API user"

      assert page.has_text?("Successfully created API user")

      click_link "Change Name"
      fill_in "Name", with: "Collections Application"
      click_button "Change name"
      assert page.has_text?("Updated user content.store@gov.uk successfully")

      click_link "Change Email"
      fill_in "Email", with: "collections@gov.uk"
      click_button "Change email"
      assert page.has_text?("Updated user collections@gov.uk successfully")
    end

    should "be able to authorise application access and manage permissions for an API user which should get recorded in event log" do
      create(:application, name: "Whitehall", with_non_delegated_supported_permissions: ["Managing Editor", SupportedPermission::SIGNIN_NAME])

      click_link @api_user.name
      click_link "Manage tokens"
      click_link "Add application token"

      select "Whitehall", from: "Application"
      click_button "Create access token"

      token = @api_user.authorisations.last.token
      assert page.has_selector?("div[role='alert']", text: /Make sure to copy the access token for Whitehall now. You won't be able to see it again!/)
      assert page.has_selector?("div[role='alert'] label", text: /Access token for Whitehall/)
      assert page.has_selector?("div[role='alert'] input[value='#{token}']")

      # shows truncated token
      assert page.has_selector?("code", text: token[0..7].to_s)
      assert_not page.has_selector?("code", text: token[9..-9].to_s)
      assert page.has_selector?("code", text: token[-8..].to_s)

      click_link @api_user.name
      click_link "Manage permissions"
      click_link "Update permissions for Whitehall"
      check "Managing Editor"
      click_button "Update permissions"

      click_link @api_user.name
      click_link "Manage permissions"

      assert_user_has_signin_permission_for(@api_user, "Whitehall")
      assert_has_access_token_for("Whitehall")
      assert_has_other_permissions("Whitehall", "Managing Editor")

      uncheck "Managing Editor"
      click_button "Update permissions"

      click_link @api_user.name
      click_link "Manage permissions"

      assert_user_has_signin_permission_for(@api_user, "Whitehall")
      assert_has_access_token_for("Whitehall")

      click_link @api_user.name
      click_link "View account access log"
      assert page.has_text?("Access token generated for Whitehall by #{@superadmin.name}")
    end

    should "be able to revoke application access for an API user which should get recorded in event log" do
      click_link @api_user.name
      click_link "Manage tokens"

      assert page.has_selector?(".govuk-summary-card__title", text: @application.name)
      click_link "Revoke"
      click_button "Revoke"

      assert page.has_text?("Access for #{@application.name} was revoked")
      assert_not page.has_selector?(".govuk-summary-card__title", text: @application.name)

      click_link @api_user.name
      click_link "View account access log"
      assert page.has_text?("Access token revoked for #{@application.name} by #{@superadmin.name}")
    end

    should "be able to suspend and unsuspend API user" do
      click_link @api_user.name
      click_link "Suspend user"

      check "Suspended?"
      fill_in "Reason for suspension", with: "Stole data"
      click_button "Save"

      assert page.has_selector?(".govuk-notification-banner__heading", text: "#{@api_user.email} is now suspended.")

      click_link "Unsuspend user"
      uncheck "Suspended?"
      click_button "Save"

      assert page.has_selector?(".govuk-notification-banner__heading", text: "#{@api_user.email} is now active.")
    end
  end

  def assert_user_has_signin_permission_for(user, application_name)
    assert user.has_access_to?(Doorkeeper::Application.find_by!(name: application_name))
  end

  def assert_has_access_token_for(application_name)
    table = find("table caption[text()='Apps #{@api_user.name} has access to']").ancestor("table")
    assert table.has_content?(application_name)
  end

  def assert_has_other_permissions(application_name, permission_name)
    click_link "Update permissions for #{application_name}"
    assert page.has_checked_field?(permission_name)
  end
end
