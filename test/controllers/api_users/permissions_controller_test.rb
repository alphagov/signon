require "test_helper"

class ApiUsers::PermissionsControllerTest < ActionController::TestCase
  context "#edit" do
    context "when the granting user is authorised to edit another's permissions" do
      should "render a page with checkboxes for the grantable permissions and a hidden field for the signin permission so that it is not removed" do
        application = create(:application)
        old_grantable_permission = create(:supported_permission, application:)
        new_grantable_permission = create(:supported_permission, application:)
        new_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

        api_user = create(:api_user, with_permissions: { application => [old_grantable_permission.name] })
        create(:access_token, application:, resource_owner_id: api_user.id)

        current_user = create(:superadmin_user)
        sign_in current_user

        stub_policy_for_navigation_links(current_user)
        stub_policy current_user, api_user, edit?: true

        get :edit, params: { api_user_id: api_user, application_id: application }

        assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{old_grantable_permission.id}']"
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_grantable_permission.id}']"
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_non_grantable_permission.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
        assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
      end

      should "allow access to users with a revoked access token when there is at least one non-revoked access token" do
        sign_in create(:superadmin_user)

        application = create(:application)
        api_user = create(:api_user)
        create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :edit, params: { api_user_id: api_user, application_id: application }

        assert_response :success
      end
    end

    context "when the granting user shouldn't be able to edit another's permissions" do
      should "prevent unauthenticated users" do
        application = create(:application)
        api_user = create(:api_user)

        get :edit, params: { api_user_id: api_user, application_id: application }

        assert_not_authenticated
      end

      should "prevent unauthorised users" do
        application = create(:application)
        api_user = create(:api_user)
        create(:access_token, application:, resource_owner_id: api_user.id)

        current_user = create(:superadmin_user)
        sign_in current_user

        stub_policy current_user, api_user, edit?: false

        get :edit, params: { api_user_id: api_user, application_id: application }

        assert_not_authorised
      end

      should "prevent access if the user does not have an access token for the application" do
        application = create(:application)
        api_user = create(:api_user)

        current_user = create(:superadmin_user)
        sign_in current_user

        assert_raises(ActiveRecord::RecordNotFound) do
          get :edit, params: { api_user_id: api_user, application_id: application }
        end
      end

      should "prevent access if the user only has a revoked access token" do
        sign_in create(:superadmin_user)

        application = create(:application)
        api_user = create(:api_user)
        create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)

        assert_raises(ActiveRecord::RecordNotFound) do
          get :edit, params: { api_user_id: api_user, application_id: application }
        end
      end

      should "prevent editing permissions for retired applications" do
        sign_in create(:superadmin_user)

        application = create(:application, retired: true)
        api_user = create(:api_user)
        create(:access_token, resource_owner_id: api_user.id, application:)

        assert_raises(ActiveRecord::RecordNotFound) do
          get :edit, params: { api_user_id: api_user, application_id: application }
        end
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

      patch :update, params: {
        api_user_id: api_user,
        application_id: application,
        application: { supported_permission_ids: [new_permission.id] },
      }

      assert_redirected_to api_user_applications_path(api_user)
      assert_same_elements [application.signin_permission, new_permission], api_user.reload.supported_permissions
    end

    should "when updating permissions for app A, prevent additionally adding or removing permissions for app B" do
      application_a = create(:application)
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
      create(:access_token, application: application_b, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      patch :update, params: {
        api_user_id: api_user,
        application_id: application_a,
        application: { supported_permission_ids: [application_a_new_permission.id, application_b_new_permission.id] },
      }

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

      assert_same_elements [
        old_non_grantable_permission,
        new_grantable_permission,
        application.signin_permission,
      ], api_user.reload.supported_permissions
    end

    should "assign the application id to the application_id flash" do
      application = create(:application)
      permission = create(:supported_permission, application:)

      api_user = create(:api_user, with_signin_permissions_for: [application])
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      patch :update, params: {
        api_user_id: api_user,
        application_id: application,
        application: { supported_permission_ids: [permission.id] },
      }

      assert_equal application.id, flash[:application_id]
    end

    should "prevent unauthorised users" do
      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: false

      patch :update, params: {
        api_user_id: api_user,
        application_id: application,
        application: { supported_permission_ids: [] },
      }

      assert_not_authorised
    end

    should "prevent updating permissions for retired applications" do
      application = create(:application, retired: true)
      permission = create(:supported_permission, application:)

      api_user = create(:api_user, with_signin_permissions_for: [application])
      create(:access_token, resource_owner_id: api_user.id, application:)

      sign_in create(:superadmin_user)

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: {
          api_user_id: api_user,
          application_id: application,
          application: { supported_permission_ids: [permission.id] },
        }
      end
    end

    should "push permission changes out to apps" do
      application = create(:application)
      permission = create(:supported_permission, application:)

      api_user = create(:api_user, with_signin_permissions_for: [application])
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      PermissionUpdater.expects(:perform_on).with(api_user)

      patch :update, params: {
        api_user_id: api_user,
        application_id: application,
        application: { supported_permission_ids: [permission.id] },
      }
    end

    should "prevent updating permissions if the user only has a revoked access token" do
      application = create(:application)
      permission = create(:supported_permission, application:)

      api_user = create(:api_user, with_signin_permissions_for: [application])

      create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: {
          api_user_id: api_user,
          application_id: application,
          application: { supported_permission_ids: [permission] },
        }
      end
    end

    should "allow updating when the user has revoked access tokens when there is at least one non-revoked access token" do
      application = create(:application)
      permission = create(:supported_permission, application:)

      api_user = create(:api_user, with_signin_permissions_for: [application])
      create(:access_token, resource_owner_id: api_user.id, application:, revoked_at: Time.current)
      create(:access_token, resource_owner_id: api_user.id, application:)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      assert_nothing_raised do
        patch :update, params: {
          api_user_id: api_user,
          application_id: application,
          application: { supported_permission_ids: [permission.id] },
        }
      end
    end
  end
end
