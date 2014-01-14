require 'test_helper'
 
class GrantingPermissionsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, role: "admin")
    @user = create(:user)

    visit root_path
    signin(@admin)
  end

  should "support granting signin permissions" do
    app = create(:application, name: "MyApp")

    visit edit_admin_user_path(@user)
    check "Has access to MyApp?"
    click_button "Update User"

    permission = Permission.where(application_id: app.id, user_id: @user.id).first
    assert_equal ["signin"], permission.permissions
  end

  should "support granting app-specific permissions" do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])

    visit edit_admin_user_path(@user)
    select "write", from: "Permissions for MyApp"
    click_button "Update User"

    permission = Permission.where(application_id: app.id, user_id: @user.id).first
    assert_equal ["write"], permission.permissions
  end
end
