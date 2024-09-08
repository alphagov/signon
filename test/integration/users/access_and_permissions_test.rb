require "test_helper"

class Users::AccessAndPermissionsTest < ActionDispatch::IntegrationTest
  context "with apps that have greater than eight permissions" do
    should "support granting app-specific permissions" do
      admin = create(:superadmin_user)
      user = create(:user)
      visit root_path
      signin_with(admin)

      app = create(
        :application,
        name: "MyApp",
        with_non_delegatable_supported_permissions: %w[pre-existing removing adding never-1 never-2 never-3 never-4 never-5 never-6],
      )
      user.grant_application_signin_permission(app)
      user.grant_application_permissions(app, %w[pre-existing removing])

      visit edit_user_path(user)
      click_on "Manage permissions"
      click_on "Update permissions for MyApp"
      uncheck "removing"
      click_button "Update permissions"
      assert_includes user.permissions_for(app), "pre-existing"
      %w[removing adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
        assert_not_includes user.permissions_for(app), permission
      end

      click_on "Update permissions for MyApp"
      click_button "Add and finish"
      flash = find("div[role='alert']")
      assert flash.has_content?("You must select a permission.")

      select "adding"
      click_button "Add and finish"
      assert_includes user.permissions_for(app), "pre-existing"
      assert_includes user.permissions_for(app), "adding"
      %w[removing never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
        assert_not_includes user.permissions_for(app), permission
      end
    end

    context "when the user already has some but not all permissions" do
      should "show the new and current permissions forms" do
        admin = create(:superadmin_user)
        user = create(:user)
        visit root_path
        signin_with(admin)

        app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[pre-existing never-1 never-2 gonna run around and desert you],
        )
        user.grant_application_signin_permission(app)
        user.grant_application_permissions(app, %w[pre-existing])

        # when I visit the path to edit the user's permissions for the app
        visit edit_user_path(user)
        click_on "Manage permissions"
        click_on "Update permissions for MyApp"
        assert_current_url edit_user_application_permissions_path(user, app)

        # the new permissions form exists
        assert_selector "#new_permission_id"

        # the current permissions form exists
        assert_selector "legend", text: "Current permissions"
        assert_selector ".govuk-hint", text: "Clear the checkbox and save changes to remove a permission."
        assert_selector ".govuk-label", text: "pre-existing"
        assert_selector ".govuk-button", text: "Update permissions"
      end
    end

    context "when the user has all permissions" do
      should "only show the current permissions form" do
        admin = create(:superadmin_user)
        user = create(:user)
        visit root_path
        signin_with(admin)

        app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[Gotta catch 'em all I know it's my destiny],
        )
        @adding_permission = SupportedPermission.find_by(name: "adding")
        user.grant_application_signin_permission(app)
        user.grant_application_permissions(app, %w[Gotta catch 'em all I know it's my destiny])

        # when I visit the path to edit the user's permissions for the app
        visit edit_user_path(user)
        click_on "Manage permissions"
        click_on "Update permissions for MyApp"
        assert_current_url edit_user_application_permissions_path(user, app)

        # the new permissions does not exist
        assert_no_selector "#new_permission_id", visible: false

        # the current permissions form exists
        assert_selector "legend", text: "Current permissions"
        assert_selector ".govuk-hint", text: "Clear the checkbox and save changes to remove a permission."
        assert_selector ".govuk-button", text: "Update permissions"
      end
    end

    context "when the user has no permissions" do
      should "only show the new permissions form" do
        admin = create(:superadmin_user)
        user = create(:user)
        visit root_path
        signin_with(admin)

        app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[never-1 never-2 never-3 never-4 never-5 gonna make you cry],
        )
        user.grant_application_signin_permission(app)

        # when I visit the path to edit the user's permissions for the app
        visit edit_user_path(user)
        click_on "Manage permissions"
        click_on "Update permissions for MyApp"
        assert_current_url edit_user_application_permissions_path(user, app)

        # the new permissions form exists
        assert_selector "#new_permission_id", visible: false

        # the current permissions form does not exist
        assert_no_selector "legend", text: "Current permissions"
        assert_no_selector ".govuk-hint", text: "Clear the checkbox and save changes to remove a permission."
        assert_no_selector ".govuk-button", text: "Update permissions"
      end
    end

    context "with JavaScript enabled" do
      setup do
        use_javascript_driver

        admin = create(:superadmin_user)
        @user = create(:user)
        visit root_path
        signin_with(admin)

        @app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[pre-existing adding never-1 never-2 never-3 never-4 never-5 never-6 never-7],
        )
        @adding_permission = SupportedPermission.find_by(name: "adding")
        @user.grant_application_signin_permission(@app)
        @user.grant_application_permissions(@app, %w[pre-existing])

        # when I visit the path to edit the user's permissions for the app
        visit edit_user_path(@user)
        click_on "Manage permissions"
        click_on "Update permissions for MyApp"
        assert_current_url edit_user_application_permissions_path(@user, @app)

        # the autocomplete and select elements are empty
        @autocomplete_input = find(".autocomplete__input")
        @select_element = find("#new_permission_id-select", visible: false)
        assert_equal "", @autocomplete_input.value
        assert_equal "", @select_element.value

        # when I type a few characters from a permission called "adding"
        @autocomplete_input.fill_in with: "add"
        autocomplete_option = find(".autocomplete__option")

        # the autcomplete value reflects what I typed, a matching option appears, but the select element remains empty
        assert_equal "add", @autocomplete_input.value
        assert_equal @adding_permission.name, autocomplete_option.text
        assert_equal "", @select_element.value

        # when I click on the matching option
        autocomplete_option.click

        # the autocomplete and select elements reflect my selection
        assert_equal @adding_permission.name, @autocomplete_input.value
        assert_equal @adding_permission.id.to_s, @select_element.value
      end

      should "be able to add permissions" do
        # when I try to add the permission
        click_button "Add and finish"

        # I can see that the permission has been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        assert_includes @user.permissions_for(@app), "adding"
        %w[never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end

        assert_current_url user_applications_path(@user)
      end

      should "add permissions then redirect back to the form when clicking 'Add'" do
        click_button "Add"

        # I can see that the permission has been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        assert_includes @user.permissions_for(@app), "adding"
        %w[never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end

        assert_current_url edit_user_application_permissions_path(@user, @app)
      end

      should "reset the value of the select element when it no longer matches what's shown in the autocomplete input" do
        # when I remove a character from the autocomplete element
        @autocomplete_input.fill_in with: "addin"

        # the autocomplete element reflects the change, the relevant option reappears, and the select element is reset to empty
        autocomplete_option = find(".autocomplete__option")
        assert_equal "addin", @autocomplete_input.value
        assert_equal @adding_permission.name, autocomplete_option.text
        assert_equal "", @select_element.value

        # when I try to add the permission
        click_button "Add and finish"

        # I can see that the permission has not been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        %w[adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end
      end

      should "clear the value of the select and autocomplete elements when clicking the clear button" do
        # when I click on the clear button
        click_button "Clear selection"

        # the autocomplete and select elements are reset to empty
        assert_equal "", @autocomplete_input.value
        assert_equal "", @select_element.value

        # when I try to add the permission
        click_button "Add and finish"

        # I can see that the permission has not been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        %w[adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end
      end

      should "clear the value of the select and autocomplete elements when hitting space on the clear button" do
        # when I press space on the clear button
        clear_button = find(".js-autocomplete__clear-button")
        clear_button.native.send_keys :space

        # the autocomplete and select elements are reset to empty
        assert_equal "", @autocomplete_input.value
        assert_equal "", @select_element.value

        # when I try to add the permission
        click_button "Add and finish"

        # I can see that the permission has not been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        %w[adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end
      end

      should "clear the value of the select and autocomplete elements when hitting enter on the clear button" do
        # when I press enter on the clear button
        clear_button = find(".js-autocomplete__clear-button")
        clear_button.native.send_keys :enter

        # the autocomplete and select elements are reset to empty
        assert_equal "", @autocomplete_input.value
        assert_equal "", @select_element.value

        # when I try to add the permission
        click_button "Add and finish"

        # I can see that the permission has not been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        %w[adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end
      end
    end
  end
end
