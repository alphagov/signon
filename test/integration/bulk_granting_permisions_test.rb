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

    permissions = {
      @application => %w[signin],
    }

    perform_bulk_grant_as_user(user, permissions)
  end

  should "admin user can grant multiple permissions to all users in one go" do
    user = create(:admin_user)

    permissions = {
      @application => %w[signin],
    }

    perform_bulk_grant_as_user(user, permissions)
  end

  should "super organisation admin user can not grant multiple permissions to all users in one go" do
    user = create(:super_org_admin)

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

  def perform_bulk_grant_as_user(acting_user, permissions)
    perform_enqueued_jobs do
      visit root_path
      signin_with(acting_user)

      visit new_bulk_grant_permission_set_path

      select permissions.keys.first.name, from: "Application"

      click_button "Grant access to all users"

      assert_response_contains("Scheduled grant of #{permissions.map { |_app, perms| perms.count }.inject(:+)} permissions to all users")
      assert_response_contains("Granting permissions to all users")
      assert_response_contains("All #{User.all.count} users processed")

      permissions.each do |application, app_permissions|
        app_permissions_line = "#{application.name} "
        app_permissions_line <<
          if app_permissions.include? "signin"
            "Yes"
          else
            "No"
          end
        assert_response_contains app_permissions_line
      end

      [acting_user, @users, @org_admins, @admins, @superadmins].flatten.each do |user|
        user.reload
        assert_has_permissions user, permissions
      end
    end
  end

  def assert_has_permissions(user, permissions)
    permissions.each do |application, app_permissions|
      assert_equal app_permissions.sort, user.permissions_for(application).sort
    end
  end
end
