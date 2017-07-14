require 'test_helper'

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
      check "Has access to MyApp?"
      click_button "Update User"

      assert @user.has_access_to?(app)
    end

    should "support granting app-specific permissions" do
      app = create(:application, name: "MyApp",
                   with_supported_permissions: ["pre-existing", "adding", "never"])
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      select "adding", from: "Permissions for MyApp"
      click_button "Update User"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      create(:application, name: "MyApp", with_supported_permissions_not_grantable_from_ui: ['user_update_permission'])

      visit edit_user_path(@user)
      assert page.has_no_select?('Permissions for MyApp', options: ['user_update_permission'])
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
      check "Has access to MyApp?"
      click_button "Update User"

      assert @user.has_access_to?(app)
    end

    should "support granting app-specific permissions" do
      app = create(:application, name: "MyApp",
                   with_supported_permissions: ["pre-existing", "adding", "never"])
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      select "adding", from: "Permissions for MyApp"
      click_button "Update User"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      create(:application, name: "MyApp", with_supported_permissions_not_grantable_from_ui: ['user_update_permission'])

      visit edit_user_path(@user)
      assert page.has_no_select?('Permissions for MyApp', options: ['user_update_permission'])
    end
  end

  context "as an org admin" do
    setup do
      @admin = create(:organisation_admin)
      @user = create(:user, organisation: @admin.organisation)

      visit root_path
      signin_with(@admin)
    end

    should "support granting signin permissions to delegatable apps that the org admin has access to" do
      app = create(:application, name: 'MyApp', with_delegatable_supported_permissions: ["signin"])
      @admin.grant_application_permission(app, 'signin')

      visit edit_user_path(@user)
      check "Has access to MyApp?"
      click_button "Update User"

      assert @user.reload.has_access_to?(app)
    end

    should "not support granting signin permissions to non-delegatable apps that the org admin has access to" do
      app = create(:application, name: 'MyApp')
      signin_permission = app.signin_permission
      signin_permission.update_attributes(delegatable: false)
      @admin.grant_application_permission(app, 'signin')

      visit edit_user_path(@user)
      assert page.has_no_field? "Has access to MyApp?"
    end

    should "not support granting signin permissions to apps that the org admin doesn't have access to" do
      create(:application, name: 'MyApp', with_delegatable_supported_permissions: ['signin'])

      visit edit_user_path(@user)
      assert page.has_no_field? "Has access to MyApp?"
    end

    should "not remove permissions the user has that the org admin does not have" do
      app = create(:application, name: 'MyApp')
      @user.grant_application_permission(app, 'signin')

      visit edit_user_path(@user)
      click_button "Update User"

      assert @user.reload.has_access_to?(app)
    end

    should "not remove permissions the user has that the org admin cannot delegate" do
      app = create(:application, name: 'MyApp')
      app.signin_permission.update_attributes(delegatable: false)
      @admin.grant_application_permission(app, 'signin')
      @user.grant_application_permission(app, 'signin')

      visit edit_user_path(@user)
      click_button "Update User"

      assert @user.reload.has_access_to?(app)
    end

    should "support granting app-specific permissions" do
      app = create(:application, name: "MyApp",
                   with_supported_permissions: ["pre-existing", "adding", "never"])
      @admin.grant_application_permission(app, 'signin')
      @user.grant_application_permission(app, "pre-existing")

      visit edit_user_path(@user)
      select "adding", from: "Permissions for MyApp"
      click_button "Update User"

      assert_includes @user.permissions_for(app), "pre-existing"
      assert_includes @user.permissions_for(app), "adding"
      assert_not_includes @user.permissions_for(app), "never"
    end

    should "not be able to grant permissions that are not grantable_from_ui" do
      app = create(:application, name: "MyApp", with_supported_permissions_not_grantable_from_ui: ['user_update_permission'])
      @admin.grant_application_permission(app, 'signin')

      visit edit_user_path(@user)
      assert page.has_no_select?('Permissions for MyApp', options: ['user_update_permission'])
    end
  end
end
