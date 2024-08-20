require "test_helper"

class Users::ApplicationsTest < ActionDispatch::IntegrationTest
  should "allow admins to grant users access to apps" do
    user = create(:user, name: "user-name")
    create(:application, name: "app-name")

    admin_user = create(:admin_user)
    visit new_user_session_path
    signin_with admin_user

    visit user_applications_path(user)

    table = find("table caption[text()='Apps user-name does not have access to']").ancestor("table")
    assert table.has_content?("app-name")

    click_on "Grant access to app-name"

    table = find("table caption[text()='Apps user-name has access to']").ancestor("table")
    assert table.has_content?("app-name")
  end

  should "allow admins to remove users' access to apps" do
    user = create(:user, name: "user-name")
    application = create(:application, name: "app-name")
    user.grant_application_signin_permission(application)

    admin_user = create(:admin_user)
    visit new_user_session_path
    signin_with admin_user

    visit user_applications_path(user)

    table = find("table caption[text()='Apps user-name has access to']").ancestor("table")
    assert table.has_content?("app-name")

    click_on "Remove access to app-name"
    click_on "Confirm"

    table = find("table caption[text()='Apps user-name does not have access to']").ancestor("table")
    assert table.has_content?("app-name")
  end

  should "allow admins to update users' permissions for apps" do
    application = create(:application, name: "app-name", with_non_delegatable_supported_permissions: %w[perm1 perm2])
    application.signin_permission.update!(delegatable: true)

    user = create(:admin_user)
    user.grant_application_signin_permission(application)
    user.grant_application_permission(application, "perm1")

    admin_user = create(:admin_user)
    visit new_user_session_path
    signin_with admin_user

    visit user_applications_path(user)

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
