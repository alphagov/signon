require "test_helper"

class Account::AccessAndPermissionsTest < ActionDispatch::IntegrationTest
  context "removing access to apps" do
    setup do
      application = create(:application, name: "app-name", description: "app-description")
      @user = create(:admin_user)
      @user.grant_application_signin_permission(application)
    end

    should "allow admins to remove their access to apps" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      click_on "Remove access to app-name"
      click_on "Confirm"

      table = find("table caption[text()='Apps you don\\'t have access to']").ancestor("table")
      assert table.has_content?("app-name")
    end
  end

  %i[superadmin admin].each do |admin_role|
    context "as a #{admin_role}" do
      setup do
        @application = create(:application, name: "app-name")
        @user = create(:"#{admin_role}_user", with_signin_permissions_for: [@application])

        visit new_user_session_path
        signin_with @user
      end

      should "support granting self app-specific permissions" do
        create(:supported_permission, application: @application, name: "perm1")
        create(:supported_permission, application: @application, name: "perm2")
        @user.grant_application_permission(@application, "perm1")

        visit account_applications_path

        click_on "Update permissions for app-name"

        assert page.has_checked_field?("perm1")
        assert page.has_unchecked_field?("perm2")

        check "perm2"
        click_button "Update permissions"

        success_flash = find("div[role='alert']")
        assert success_flash.has_content?("perm1")
        assert success_flash.has_content?("perm2")
      end

      should "be able to grant delegatable and non-delegatable permissions" do
        create(:delegatable_supported_permission, application: @application, name: "delegatable_perm")
        create(:non_delegatable_supported_permission, application: @application, name: "non_delegatable_perm")

        visit account_applications_path

        click_link "Update permissions for app-name"

        assert page.has_field?("delegatable_perm")
        assert page.has_field?("non_delegatable_perm")
      end

      should "not be able to grant permissions that are not grantable_from_ui" do
        create(:supported_permission, application: @application, grantable_from_ui: true, name: "grantable_from_ui_perm")
        create(:supported_permission, application: @application, grantable_from_ui: false, name: "not_grantable_from_ui_perm")

        visit account_applications_path

        click_link "Update permissions for app-name"

        assert page.has_field?("grantable_from_ui_perm")
        assert page.has_no_field?("not_grantable_from_ui_perm")
      end
    end
  end

  %i[super_organisation_admin organisation_admin].each do |publishing_manager_role|
    context "as a #{publishing_manager_role}" do
      setup do
        @application = create(:application, name: "app-name")
        @user = create(:"#{publishing_manager_role}_user", with_signin_permissions_for: [@application])

        visit new_user_session_path
        signin_with @user
      end

      should "support granting self app-specific permissions" do
        create(:delegatable_supported_permission, application: @application, name: "perm1")
        create(:delegatable_supported_permission, application: @application, name: "perm2")
        @user.grant_application_permission(@application, "perm1")

        visit account_applications_path

        click_on "Update permissions for app-name"

        assert page.has_checked_field?("perm1")
        assert page.has_unchecked_field?("perm2")

        check "perm2"
        click_button "Update permissions"

        success_flash = find("div[role='alert']")
        assert success_flash.has_content?("perm1")
        assert success_flash.has_content?("perm2")
      end

      should "not be able to grant permissions that are non-delegatable" do
        create(:delegatable_supported_permission, application: @application, name: "delegatable_perm")
        create(:non_delegatable_supported_permission, application: @application, name: "non_delegatable_perm")

        visit account_applications_path

        click_link "Update permissions for app-name"

        assert page.has_field?("delegatable_perm")
        assert page.has_no_field?("non_delegatable_perm")

        assert_selector ".govuk-inset-text", text: "Below, you will only see permissions that you are authorised to manage. You can also view all the permissions you have for app-name."
      end

      should "not be able to grant permissions that are not grantable_from_ui" do
        create(:delegatable_supported_permission, application: @application, grantable_from_ui: true, name: "grantable_from_ui_perm")
        create(:delegatable_supported_permission, application: @application, grantable_from_ui: false, name: "not_grantable_from_ui_perm")

        visit account_applications_path

        click_link "Update permissions for app-name"

        assert page.has_field?("grantable_from_ui_perm")
        assert page.has_no_field?("not_grantable_from_ui_perm")
      end
    end
  end

  context "with apps that have greater than eight permissions" do
    should "support granting self app-specific permissions" do
      user = create(:superadmin_user)

      app = create(:application, name: "app-with-9-permissions", description: "app-description", with_non_delegatable_supported_permissions: %w[pre-existing removing adding never-1 never-2 never-3 never-4 never-5 never-6])
      app.signin_permission.update!(delegatable: true)
      user.grant_application_signin_permission(app)
      user.grant_application_permissions(app, %w[pre-existing removing])

      visit new_user_session_path
      signin_with user

      visit account_applications_path
      click_on "Update permissions for app-with-9-permissions"
      assert page.has_checked_field?("pre-existing")
      assert page.has_checked_field?("removing")
      uncheck "removing"
      click_button "Update permissions"
      success_flash = find("div[role='alert']")
      assert success_flash.has_content?("pre-existing")
      %w[removing adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
        assert_not success_flash.has_content?(permission)
      end

      click_on "Update permissions for app-with-9-permissions"
      click_button "Add and finish"
      flash = find("div[role='alert']")
      assert flash.has_content?("You must select a permission.")

      select "adding"
      click_button "Add and finish"
      flash = find("div[role='alert']")
      assert flash.has_content?("pre-existing")
      assert flash.has_content?("adding")
      %w[removing never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
        assert_not flash.has_content?(permission)
      end
    end

    context "when the user already has some but not all permissions" do
      should "show the new and current permissions forms" do
        user = create(:superadmin_user)

        visit root_path
        signin_with(user)

        app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[pre-existing never-1 never-2 never-3 never-4 gonna give you up],
        )
        app.signin_permission.update!(delegatable: true)
        user.grant_application_signin_permission(app)
        user.grant_application_permissions(app, %w[pre-existing])

        # when I visit the path to edit my permissions for the app
        visit account_applications_path
        click_on "Update permissions for MyApp"
        assert_current_url edit_account_application_permissions_path(app)

        # the new permissions form exists with autocomplete and select elements
        assert_selector "#new_permission_id"

        # the current permissions form does not exist
        assert_selector "legend", text: "Current permissions"
        assert_selector ".govuk-hint", text: "Clear the checkbox and save changes to remove a permission."
        assert_selector ".govuk-label", text: "pre-existing"
        assert_selector ".govuk-button", text: "Update permissions"
      end
    end

    context "when the user has all permissions" do
      should "only show the current permissions form" do
        user = create(:superadmin_user)

        visit root_path
        signin_with(user)

        app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[Gotta catch 'em all I know it's my destiny],
        )
        app.signin_permission.update!(delegatable: true)
        user.grant_application_signin_permission(app)
        user.grant_application_permissions(app, %w[Gotta catch 'em all I know it's my destiny])

        # when I visit the path to edit my permissions for the app
        visit account_applications_path
        click_on "Update permissions for MyApp"
        assert_current_url edit_account_application_permissions_path(app)

        # the new permissions form exists with autocomplete and select elements
        assert_no_selector "#new_permission_id"

        # the current permissions form does not exist
        assert_selector "legend", text: "Current permissions"
        assert_selector ".govuk-hint", text: "Clear the checkbox and save changes to remove a permission."
        assert_selector ".govuk-button", text: "Update permissions"
      end
    end

    context "when the user has no permissions" do
      should "only show the new permissions form" do
        user = create(:superadmin_user)

        visit root_path
        signin_with(user)

        app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[never-1 never-2 never-3 never-4 never-5 gonna let you down],
        )
        app.signin_permission.update!(delegatable: true)
        user.grant_application_signin_permission(app)

        # when I visit the path to edit my permissions for the app
        visit account_applications_path
        click_on "Update permissions for MyApp"
        assert_current_url edit_account_application_permissions_path(app)

        # the new permissions form exists with autocomplete and select elements
        assert_selector "#new_permission_id"

        # the current permissions form does not exist
        assert_no_selector "legend", text: "Current permissions"
        assert_no_selector ".govuk-hint", text: "Clear the checkbox and save changes to remove a permission."
        assert_no_selector ".govuk-button", text: "Update permissions"
      end
    end

    context "with JavaScript enabled" do
      setup do
        use_javascript_driver

        @user = create(:superadmin_user)

        visit root_path
        signin_with(@user)

        @app = create(
          :application,
          name: "MyApp",
          with_non_delegatable_supported_permissions: %w[pre-existing adding never-1 never-2 never-3 never-4 never-5 never-6 never-7],
        )
        @app.signin_permission.update!(delegatable: true)
        @adding_permission = SupportedPermission.find_by(name: "adding")
        @user.grant_application_signin_permission(@app)
        @user.grant_application_permissions(@app, %w[pre-existing])

        # when I visit the path to edit my permissions for the app
        visit account_applications_path
        click_on "Update permissions for MyApp"
        assert_current_url edit_account_application_permissions_path(@app)

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

        assert_current_url account_applications_path
      end

      should "add permissions then redirect back to the form when clicking 'Add'" do
        click_button "Add"

        # I can see that the permission has been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        assert_includes @user.permissions_for(@app), "adding"
        %w[never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end

        assert_current_url edit_account_application_permissions_path(@app)
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
