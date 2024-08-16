require "test_helper"

class ApiUsers::PermissionsControllerTest < ActionController::TestCase
  context "#edit" do
    should "prevent unauthenticated users" do
      application = create(:application)
      api_user = create(:api_user)

      get :edit, params: { api_user_id: api_user, application_id: application }

      assert_not_authenticated
    end

    should "prevent unauthorized users" do
      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, edit?: false

      get :edit, params: { api_user_id: api_user, application_id: application }

      assert_not_authorised
    end

    should "display checkboxes for the grantable permissions" do
      application = create(:application)
      perm1 = create(:supported_permission, application:, name: "perm-1")
      perm2 = create(:supported_permission, application:, name: "perm-2")
      perm3 = create(:supported_permission, application:, name: "perm-3", grantable_from_ui: false)
      api_user = create(:api_user, with_permissions: { application => %w[perm-1] })
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy_for_navigation_links(current_user)
      stub_policy current_user, api_user, edit?: true

      get :edit, params: { api_user_id: api_user, application_id: application }

      assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{perm1.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{perm2.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{perm3.id}']", count: 0
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
    end

    should "include a hidden field for the signin permission so that it is not removed" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[perm-1])
      api_user = create(:api_user, with_permissions: { application => %w[perm-1] })
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy_for_navigation_links(current_user)
      stub_policy current_user, api_user, edit?: true

      get :edit, params: { api_user_id: api_user, application_id: application }

      assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
    end

    should "exclude retired applications" do
      sign_in create(:superadmin_user)

      application = create(:application, retired: true)
      api_user = create(:api_user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { api_user_id: api_user, application_id: application }
      end
    end

    should "exclude applications with revoked access tokens" do
      sign_in create(:superadmin_user)

      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { api_user_id: api_user, application_id: application }
      end
    end

    should "include applications with revoked access tokens when there is at least one non-revoked access token" do
      sign_in create(:superadmin_user)

      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)
      create(:access_token, resource_owner_id: api_user.id, application:)

      get :edit, params: { api_user_id: api_user, application_id: application }

      assert_response :success
    end

    should "raise an exception if the user does not have an access token for the application" do
      application = create(:application)
      api_user = create(:api_user)

      current_user = create(:superadmin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { api_user_id: api_user, application_id: application }
      end
    end
  end

  context "#update" do
    should "prevent unauthenticated users" do
      application = create(:application)
      api_user = create(:api_user)

      patch :update, params: { api_user_id: api_user, application_id: application }

      assert_not_authenticated
    end

    should "update non-signin permissions, retaining the signin permission, then redirect to the API applications path" do
      application = create(:application)
      old_permission = create(:supported_permission, application:)
      new_permission = create(:supported_permission, application:)

      api_user = create(:api_user,
                        with_signin_permissions_for: [application],
                        with_permissions: { application => [old_permission.name] })
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [new_permission.id] } }

      assert_redirected_to api_user_applications_path(api_user)
      assert_same_elements [application.signin_permission, new_permission], api_user.reload.supported_permissions
    end

    should "prevent permissions being added for apps that the current user does not have access to" do
      organisation = create(:organisation)

      allowed_application = create(:application)
      forbidden_application = create(:application, with_non_delegatable_supported_permissions: %w[forbidden-permission])

      api_user = create(:api_user, organisation:)
      create(:access_token, application: allowed_application, resource_owner_id: api_user.id)
      create(:access_token, application: forbidden_application, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      current_user.grant_application_signin_permission(allowed_application)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      forbidden_application_permission = forbidden_application.supported_permissions.find_by!(name: "forbidden-permission")

      patch :update, params: {
        api_user_id: api_user,
        application_id: allowed_application,
        application: { supported_permission_ids: [forbidden_application_permission.id] },
      }

      api_user.reload

      assert_equal [], api_user.supported_permissions
    end

    should "when updating permissions for app A, prevent additionally adding or removing permissions for app B" do
      application_a = create(:application, with_non_delegatable_supported_permissions: %w[other])
      application_a_old_permission = create(:supported_permission, application: application_a)
      application_a_new_permission = create(:supported_permission, application: application_a)

      application_b = create(:application)
      application_b_old_permission = create(:supported_permission, application: application_b)
      application_b_new_permission = create(:supported_permission, application: application_b)

      api_user = create(:api_user,
                        with_signin_permissions_for: [application_a, application_b],
                        with_permissions: {
                          application_a => [application_a_old_permission.name],
                          application_b => [application_b_old_permission.name],
                        })

      create(:access_token, application: application_a, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      patch :update, params: { api_user_id: api_user, application_id: application_a, application: { supported_permission_ids: [application_a_new_permission.id, application_b_new_permission.id] } }

      api_user.reload

      assert_same_elements [
        application_a_new_permission,
        application_b_old_permission,
        application_a.signin_permission,
        application_b.signin_permission,
      ], api_user.supported_permissions

      assert_not_includes current_user.supported_permissions, application_a_old_permission
      assert_not_includes current_user.supported_permissions, application_b_new_permission
    end

    should "prevent permissions that are not grantable from the UI being added or removed" do
      application = create(:application)
      old_grantable_permission = create(:supported_permission, application:)
      new_grantable_permission = create(:supported_permission, application:)
      old_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)
      new_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

      api_user = create(
        :api_user,
        with_signin_permissions_for: [application],
        with_permissions: { application => [old_grantable_permission.name, old_non_grantable_permission.name] },
      )
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      patch :update, params: {
        api_user_id: api_user,
        application_id: application,
        application: { supported_permission_ids: [new_grantable_permission.id, new_non_grantable_permission.id] },
      }

      api_user.reload

      assert_same_elements [
        old_non_grantable_permission,
        new_grantable_permission,
        application.signin_permission,
      ], api_user.supported_permissions
    end

    should "assign the application id to the application_id flash" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[permission])
      api_user = create(:api_user)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      permission = application.supported_permissions.find_by(name: "permission")

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [permission.id] } }

      assert_equal application.id, flash[:application_id]
    end

    should "raise an exception if the user cannot be found" do
      application = create(:application)

      current_user = create(:superadmin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { api_user_id: "unknown-id", application_id: application, application: { supported_permission_ids: %w[id] } }
      end
    end

    should "prevent unauthorised users" do
      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: false

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [] } }

      assert_not_authorised
    end

    should "push permission changes out to apps" do
      sign_in create(:superadmin_user)

      application = create(:application, with_non_delegatable_supported_permissions: %w[permission])
      api_user = create(:api_user)
      create(:access_token, resource_owner_id: api_user.id, application:)

      permission = application.supported_permissions.find_by(name: "permission")

      PermissionUpdater.expects(:perform_on).with(api_user)

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [permission.id] } }
    end

    should "exclude applications with revoked access tokens" do
      sign_in create(:superadmin_user)

      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [] } }
      end
    end

    should "include applications with revoked access tokens when there is at least one non-revoked access token" do
      sign_in create(:superadmin_user)

      application = create(:application, with_non_delegatable_supported_permissions: %w[permission])
      api_user = create(:api_user)
      create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)
      create(:access_token, resource_owner_id: api_user.id, application:)

      permission = application.supported_permissions.find_by(name: "permission")

      assert_nothing_raised do
        patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [permission.id] } }
      end
    end
  end
end
