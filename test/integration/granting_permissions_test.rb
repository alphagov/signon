require "test_helper"

class GrantingPermissionsTest < ActionDispatch::IntegrationTest
  context "as a super admin" do
    setup do
      @admin = create(:superadmin_user)
      @user = create(:user)

      visit root_path
      signin_with(@admin)
    end

    should "support granting signin permissions" do
      app = create(:application, name: "MyApp")

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_button "Grant access to MyApp"

      assert @user.has_access_to?(app)
    end

    should "support granting app-specific permissions" do
      app = create(
        :application,
        name: "MyApp",
        with_supported_permissions: %w[pre-existing adding never],
      )
      @user.grant_application_signin_permission(app)
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_link "Update permissions for MyApp"
      check "adding"
      click_button "Update permissions"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      app = create(:application, name: "MyApp", with_supported_permissions: %w[perm], with_supported_permissions_not_grantable_from_ui: %w[user_update_permission])
      @user.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_link "Update permissions for MyApp"

      assert page.has_field?("perm")
      assert page.has_no_field?("user_update_permission")
    end
  end

  context "as an admin" do
    setup do
      @admin = create(:admin_user)
      @user = create(:user)

      visit root_path
      signin_with(@admin)
    end

    should "support granting signin permissions" do
      app = create(:application, name: "MyApp")

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_button "Grant access to MyApp"

      assert @user.has_access_to?(app)
    end

    should "support granting app-specific permissions" do
      app = create(
        :application,
        name: "MyApp",
        with_supported_permissions: %w[pre-existing adding never],
      )
      @user.grant_application_signin_permission(app)
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_link "Update permissions for MyApp"
      check "adding"
      click_button "Update permissions"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      app = create(:application, name: "MyApp", with_supported_permissions: %w[perm], with_supported_permissions_not_grantable_from_ui: %w[user_update_permission])
      @user.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_link "Update permissions for MyApp"

      assert page.has_field?("perm")
      assert page.has_no_field?("user_update_permission")
    end
  end

  context "as a super organisation admin" do
    setup do
      @super_org_admin = create(:super_organisation_admin_user)
      @user = create(:user, organisation: @super_org_admin.organisation)

      visit root_path
      signin_with(@super_org_admin)
    end

    should "support granting signin permissions to delegatable apps that the super organisation admin has access to" do
      app = create(:application, name: "MyApp", with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
      @super_org_admin.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_button "Grant access to MyApp"

      assert @user.reload.has_access_to?(app)
    end

    should "not support granting signin permissions to non-delegatable apps that the super organisation admin has access to" do
      app = create(:application, name: "MyApp")
      signin_permission = app.signin_permission
      signin_permission.update!(delegatable: false)
      @super_org_admin.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"

      assert page.has_no_button? "Grant access to MyApp?"
    end

    should "not support granting signin permissions to apps that the super organisation admin doesn't have access to" do
      create(:application, name: "MyApp", with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])

      visit edit_user_path(@user)
      click_link "Manage permissions"

      assert page.has_no_button? "Grant access to MyApp?"
    end

    should "support granting app-specific permissions" do
      app = create(
        :application,
        name: "MyApp",
        with_supported_permissions: %w[pre-existing adding never],
      )
      @super_org_admin.grant_application_signin_permission(app)
      @user.grant_application_signin_permission(app)
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_link "Update permissions for MyApp"
      check "adding"
      click_button "Update permissions"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      app = create(:application, name: "MyApp", with_supported_permissions_not_grantable_from_ui: %w[user_update_permission])
      @super_org_admin.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      assert page.has_no_select?("Permissions for MyApp", options: %w[user_update_permission])
    end
  end

  context "as an organisation admin" do
    setup do
      @organisation_admin = create(:organisation_admin_user)
      @user = create(:user, organisation: @organisation_admin.organisation)

      visit root_path
      signin_with(@organisation_admin)
    end

    should "support granting signin permissions to delegatable apps that the organisation admin has access to" do
      app = create(:application, name: "MyApp", with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
      @organisation_admin.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_button "Grant access to MyApp"

      assert @user.reload.has_access_to?(app)
    end

    should "not support granting signin permissions to non-delegatable apps that the organisation admin has access to" do
      app = create(:application, name: "MyApp")
      signin_permission = app.signin_permission
      signin_permission.update!(delegatable: false)
      @organisation_admin.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      assert page.has_no_field? "Has access to MyApp?"
    end

    should "not support granting signin permissions to apps that the organisation admin doesn't have access to" do
      create(:application, name: "MyApp", with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])

      visit edit_user_path(@user)
      click_link "Manage permissions"
      assert page.has_no_field? "Has access to MyApp?"
    end

    should "support granting app-specific permissions" do
      app = create(
        :application,
        name: "MyApp",
        with_supported_permissions: %w[pre-existing adding never],
      )
      @organisation_admin.grant_application_signin_permission(app)
      @user.grant_application_signin_permission(app)
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      click_link "Manage permissions"
      click_link "Update permissions for MyApp"
      check "adding"
      click_button "Update permissions"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      app = create(:application, name: "MyApp", with_supported_permissions_not_grantable_from_ui: %w[user_update_permission])
      @organisation_admin.grant_application_signin_permission(app)

      visit edit_user_path(@user)
      click_link "Manage permissions"
      assert page.has_no_select?("Permissions for MyApp", options: %w[user_update_permission])
    end
  end
end
