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

  context "updating permissions for an app" do
    %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @user = create(:"#{user_role}_user")
        end

        should "allow user to update their permissions for apps" do
          application = create(:application, name: "app-name", description: "app-description", with_supported_permissions: %w[perm1 perm2])
          application.signin_permission.update!(delegatable: true)
          @user.grant_application_signin_permission(application)
          @user.grant_application_permission(application, "perm1")

          visit new_user_session_path
          signin_with @user

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

        should "allow user to update their permissions on apps with greater than eight supported permissions" do
          application_with_9_permissions = create(:application, name: "app-with-9-permissions", description: "app-description", with_supported_permissions: %w[pre-existing removing adding never-1 never-2 never-3 never-4 never-5 never-6])
          application_with_9_permissions.signin_permission.update!(delegatable: true)
          @user.grant_application_signin_permission(application_with_9_permissions)
          @user.grant_application_permissions(application_with_9_permissions, %w[pre-existing removing])

          visit new_user_session_path
          signin_with @user

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
      end
    end
  end
end
