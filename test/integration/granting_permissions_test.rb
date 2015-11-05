require 'test_helper'

class GrantingPermissionsTest < ActionDispatch::IntegrationTest
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

  should "not be able to assign fields that are not grantable_from_ui" do
    create(:application, name: "MyApp", with_supported_permissions_not_grantable_from_ui: ['user_update_permission'])

    visit edit_user_path(@user)
    assert page.has_no_select?('Permissions for MyApp', options: ['user_update_permission'])
  end
end
