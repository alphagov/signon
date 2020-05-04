require "test_helper"

class BulkGrantingPermissionsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @users = create_list(:user, 2)
    @org_admins = create_list(:organisation_admin, 2)
    @admins = create_list(:admin_user, 2)
    @superadmins = create_list(:superadmin_user, 2)

    @application_one = create(:application, with_supported_permissions: %w[signin admin editor])
    @application_two = create(:application, with_supported_permissions: %w[signin reviewer])
  end

  should "superadmin user can grant multiple permissions to all users in one go" do
    user = create(:superadmin_user)

    permissions = {
      @application_one => %w[signin editor],
      @application_two => %w[reviewer],
    }

    perform_bulk_grant_as_user(user, permissions)
  end

  should "admin user can grant multiple permissions to all users in one go" do
    user = create(:admin_user)

    permissions = {
      @application_one => %w[signin editor],
      @application_two => %w[reviewer],
    }

    perform_bulk_grant_as_user(user, permissions)
  end

  should "present errors when no permissions are selected to grant" do
    user = create(:admin_user)

    visit root_path
    signin_with(user)

    visit new_bulk_grant_permission_set_path

    click_button "Grant permissions to all users"

    assert_response_contains("Couldn't schedule granting 0 permissions to all users")
    assert_response_contains("Supported permissions must not be blank. Choose at least one permission to grant to all users.")
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

      permissions.each do |application, app_permissions|
        app_permissions.each do |app_permission|
          if app_permission == "signin"
            check "Has access to #{application.name}?"
          else
            select app_permission, from: "Permissions for #{application.name}"
          end
        end
      end

      click_button "Grant permissions to all users"

      assert_response_contains("Scheduled grant of #{permissions.map { |_app, perms| perms.count }.inject(:+)} permissions to all users")
      assert_response_contains("Granting permissions to all users")
      assert_response_contains("All #{User.all.count} users processed")

      permissions.each do |application, app_permissions|
        app_permissions_line = "#{application.name} "
        app_permissions_line <<
          if app_permissions.include? "signin"
            "Yes "
          else
            "No "
          end
        app_permissions_line << (app_permissions - %w[signin]).sort.to_sentence
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
