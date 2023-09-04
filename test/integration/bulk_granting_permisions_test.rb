require "test_helper"

class BulkGrantingPermissionsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @users = create_list(:user, 2)
    @org_admins = create_list(:organisation_admin, 2)
    @admins = create_list(:admin_user, 2)
    @superadmins = create_list(:superadmin_user, 2)

    @application = create(:application, with_supported_permissions: %w[signin])
  end

  should "superadmin user can grant multiple permissions to all users in one go" do
    user = create(:superadmin_user)

    perform_bulk_grant_as_user(user, @application)
  end

  should "admin user can grant multiple permissions to all users in one go" do
    user = create(:admin_user)

    perform_bulk_grant_as_user(user, @application)
  end

  should "super organisation admin user can not grant multiple permissions to all users in one go" do
    user = create(:super_organisation_admin_user)

    visit root_path
    signin_with(user)

    visit new_bulk_grant_permission_set_path
    assert_equal root_path, current_path
  end

  should "organisation admin user can not grant multiple permissions to all users in one go" do
    user = create(:organisation_admin)

    visit root_path
    signin_with(user)

    visit new_bulk_grant_permission_set_path
    assert_equal root_path, current_path
  end

  should "normal user can not grant multiple permissions to all users in one go" do
    user = create(:user)

    visit root_path
    signin_with(user)

    visit new_bulk_grant_permission_set_path
    assert_equal root_path, current_path
  end

  def perform_bulk_grant_as_user(acting_user, application)
    perform_enqueued_jobs do
      visit root_path
      signin_with(acting_user)

      visit new_bulk_grant_permission_set_path

      select application.name, from: "Application"

      click_button "Grant access to all users"

      assert_response_contains("Scheduled grant of 1 permissions to all users")
      assert_response_contains("Result")
      assert_response_contains("All #{User.all.count} users processed")

      app_permissions_line = "#{application.name} Yes"
      assert_response_contains app_permissions_line

      [acting_user, @users, @org_admins, @admins, @superadmins].flatten.each do |user|
        user.reload
        assert_equal %w[signin], user.permissions_for(application)
      end
    end
  end
end
