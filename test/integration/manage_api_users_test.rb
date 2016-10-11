require_relative "../test_helper"

class ManageApiUsersTest < ActionDispatch::IntegrationTest
  context "as Superadmin" do
    setup do
      @application = create(:application, with_supported_permissions: ["write"])

      @superadmin = create(:superadmin_user)
      visit new_user_session_path
      signin_with(@superadmin)

      @api_user = create(:api_user, with_permissions: { @application => ["write"] })
      create(:access_token, resource_owner_id: @api_user.id, application_id: @application.id)

      within("ul.nav") do
        click_link "API Users"
      end
    end

    should "be able to view a list of API users alongwith their authorised applications" do
      assert page.has_selector?("td.email", text: @api_user.name)
      assert page.has_selector?("td.email", text: @api_user.email)
      assert page.has_selector?("td.role", text: 'Normal')

      assert page.has_selector?("abbr", text: @application.name)
      assert page.has_selector?("td:last-child", text: 'No') # suspended?
    end

    should "be able to create an API user" do
      click_link "Create API user"

      fill_in "Name", with: "Content Store Application"
      fill_in "Email", with: "content.store@gov.uk"
      click_button "Create API user"

      assert page.has_text?("Successfully created API user")
    end

    should "be able to authorise application access and manage permissions for an API user which should get recorded in event log" do
      whitehall = create(:application, name: "Whitehall", with_supported_permissions: ["Managing Editor", "signin"])

      click_link @api_user.name
      click_link "Add application token"

      select "Whitehall", from: "Application"
      click_button "Create access token"

      token = @api_user.authorisations.last.token
      assert page.has_selector?("div.alert-danger", text: "Make sure to copy the access token for Whitehall now. You won't be able to see it again!")
      assert page.has_selector?("div.alert-info", text: "Access token for Whitehall: #{token}")

      # shows truncated token
      assert page.has_selector?("code", text: "#{token[0..7]}")
      assert ! page.has_selector?("code", text: "#{token[9..-9]}")
      assert page.has_selector?("code", text: "#{token[-8..-1]}")

      select "Managing Editor", from: "Permissions for Whitehall"
      click_button "Update API user"

      assert page.has_selector?("abbr[title='Permissions: Managing Editor and signin']", text: "Whitehall")

      click_link @api_user.name

      unselect "Managing Editor", from: "Permissions for Whitehall"
      click_button "Update API user"

      assert page.has_selector?("abbr[title='Permissions: signin']", "Whitehall")

      click_link @api_user.name
      click_link "Account access log"
      assert page.has_text?("Access token generated for Whitehall by #{@superadmin.name}")
    end

    should "be able to revoke application access for an API user which should get recorded in event log" do
      click_link @api_user.name

      assert page.has_selector?("td:first-child", text: @application.name)
      click_button "Revoke"

      assert page.has_text?("Access for #{@application.name} was revoked")
      assert ! page.has_selector?("td:first-child", text: @application.name)

      click_link "Account access log"
      assert page.has_text?("Access token revoked for #{@application.name} by #{@superadmin.name}")
    end

    should "be able to regenerate application access token for an API user which should get recorded in event log" do
      click_link @api_user.name

      assert page.has_selector?("td:first-child", text: @application.name)
      click_button "Re-generate"

      assert page.has_selector?("div.alert-danger", text: "Make sure to copy the access token for #{@application.name} now. You won't be able to see it again!")
      assert page.has_selector?("div.alert-info", text: "Access token for #{@application.name}: #{@api_user.authorisations.last.token}")

      click_link "Account access log"
      assert page.has_text?("Access token re-generated for #{@application.name} by #{@superadmin.name}")
    end

    should "be able to suspend and unsuspend API user" do
      click_link @api_user.name
      click_link "Suspend user"

      check "Suspended?"
      fill_in "Reason for suspension", with: "Stole data"
      click_button "Save"

      assert page.has_selector?("p.alert-warning", text: "User suspended: Stole data")

      click_link "Unsuspend user"
      uncheck "Suspended?"
      click_button "Save"

      assert page.has_selector?(".alert-success", text: "#{@api_user.email} is now active.")
    end
  end
end
