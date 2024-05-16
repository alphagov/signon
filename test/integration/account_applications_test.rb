require "test_helper"

class AccountApplicationsTest < ActionDispatch::IntegrationTest
  context "#index" do
    setup do
      @application = create(:application, name: "app-name", description: "app-description")
      @retired_application = create(:application, retired: true, name: "retired-app-name")
      @api_only_application = create(:application, api_only: true, name: "api-only-app-name")
      @user = FactoryBot.create(:admin_user)
    end

    should "not be accessible to signed out users" do
      visit account_applications_path

      assert_current_url new_user_session_path
    end

    should "list the applications the user has access to" do
      @user.grant_application_signin_permission(@application)

      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      table = find("table caption[text()='Apps you have access to']").ancestor("table")
      assert table.has_content?("app-name")
      assert table.has_content?("app-description")
    end

    should "not list retired applications the user has access to" do
      @user.grant_application_signin_permission(@retired_application)

      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("retired-app-name")
    end

    should "not list API-only applications the user has access to" do
      @user.grant_application_signin_permission(@api_only_application)

      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("api-only-app-name")
    end

    should "list the applications the user does not have access to" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      table = find("table caption[text()='Apps you don\\'t have access to']").ancestor("table")

      assert table.has_content?("app-name")
      assert table.has_content?("app-description")
    end

    should "not list retired applications the user does not have access to" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("retired-app-name")
    end

    should "not list API-only applications the user does not have access to" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("api-only-app-name")
    end
  end

  context "granting access to apps" do
    setup do
      create(:application, name: "app-name", description: "app-description")
      @user = create(:admin_user)
    end

    should "allow admins to grant themselves access to apps" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      click_on "Grant access to app-name"

      table = find("table caption[text()='Apps you have access to']").ancestor("table")
      assert table.has_content?("app-name")
    end
  end

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

  context "viewing permissions for an app" do
    setup do
      @application = create(:application, name: "app-name", description: "app-description", with_supported_permissions: %w[perm1 perm2])
      @application.signin_permission.update!(delegatable: false)
    end

    %i[super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @user = create(:"#{user_role}_user")
          @user.grant_application_signin_permission(@application)
          @user.grant_application_permission(@application, "perm1")
        end

        should "allow user to view their permissions for apps" do
          visit new_user_session_path
          signin_with @user

          visit account_applications_path

          click_on "View permissions for app-name"

          signin_permission_row = find("table tr td:nth-child(1)", text: "signin").ancestor("tr")
          assert signin_permission_row.has_content?("Yes")

          perm1_permission_row = find("table tr td:nth-child(1)", text: "perm1").ancestor("tr")
          assert perm1_permission_row.has_content?("Yes")

          perm2_permission_row = find("table tr td:nth-child(1)", text: "perm2").ancestor("tr")
          assert perm2_permission_row.has_content?("No")
        end
      end
    end
  end

  %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
    context "as a #{user_role}" do
      should "support granting self app-specific permissions" do
        user = create(:"#{user_role}_user")
        application = create(:application, name: "app-name", description: "app-description", with_supported_permissions: %w[perm1 perm2])
        application.signin_permission.update!(delegatable: true)
        user.grant_application_signin_permission(application)
        user.grant_application_permission(application, "perm1")

        visit new_user_session_path
        signin_with user

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
    end
  end

  context "with apps that have greater than eight permissions" do
    should "support granting self app-specific permissions" do
      user = create(:superadmin_user)

      app = create(:application, name: "app-with-9-permissions", description: "app-description", with_supported_permissions: %w[pre-existing removing adding never-1 never-2 never-3 never-4 never-5 never-6])
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
      click_button "Add permission"
      flash = find("div[role='alert']")
      assert flash.has_content?("You must select a permission.")

      select "adding"
      click_button "Add permission"
      flash = find("div[role='alert']")
      assert flash.has_content?("pre-existing")
      assert flash.has_content?("adding")
      %w[removing never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
        assert_not flash.has_content?(permission)
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
          with_supported_permissions: %w[pre-existing adding never-1 never-2 never-3 never-4 never-5 never-6 never-7],
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
        click_button "Add permission"

        # I can see that the permission has been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        assert_includes @user.permissions_for(@app), "adding"
        %w[never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end
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
        click_button "Add permission"

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
        click_button "Add permission"

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
        click_button "Add permission"

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
        click_button "Add permission"

        # I can see that the permission has not been added
        assert_includes @user.permissions_for(@app), "pre-existing"
        %w[adding never-1 never-2 never-3 never-4 never-5 never-6].each do |permission|
          assert_not_includes @user.permissions_for(@app), permission
        end
      end
    end
  end
end
