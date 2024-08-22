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

      should "prevent access if the user has a revoked access token" do
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

    should "not remove permissions the user already has that are not grantable from ui" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[other], with_non_delegatable_supported_permissions_not_grantable_from_ui: %w[not_from_ui])
      api_user = create(:api_user)
      api_user.grant_application_permission(application, "not_from_ui")
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      other_permission = application.supported_permissions.find_by(name: "other")
      not_from_ui_permission = application.supported_permissions.find_by(name: "not_from_ui")

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [other_permission.id] } }

      api_user.reload

      assert_same_elements [other_permission, not_from_ui_permission], api_user.supported_permissions
    end

    should "prevent permissions being added for other apps" do
      other_application = create(:application, with_non_delegatable_supported_permissions: %w[other])
      application = create(:application)
      api_user = create(:api_user)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      other_permission = other_application.supported_permissions.find_by(name: "other")

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [other_permission.id] } }

      api_user.reload

      assert_equal [], api_user.supported_permissions
    end

    should "prevent permissions being added that are not grantable from the ui" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[other], with_non_delegatable_supported_permissions_not_grantable_from_ui: %w[not_from_ui])
      api_user = create(:api_user)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, update?: true

      not_from_ui_permission = application.supported_permissions.find_by(name: "not_from_ui")

      patch :update, params: { api_user_id: api_user, application_id: application, application: { supported_permission_ids: [not_from_ui_permission.id] } }

      api_user.reload

      assert_equal [], api_user.supported_permissions
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
