require "test_helper"

class ApiUsersControllerTest < ActionController::TestCase
  context "as admin user" do
    setup do
      @admin = create(:admin_user)
      sign_in @admin
    end

    should "not be able to access API user's list" do
      get :index

      assert_not_authorised
    end

    should "not be able to view API user create form" do
      get :new

      assert_not_authorised
    end
  end

  context "as superadmin" do
    setup do
      @superadmin = create(:superadmin_user)
      sign_in @superadmin
    end

    context "GET index" do
      should "list api users" do
        create(:api_user, email: "api_user@email.com")
        get :index
        assert_select "td", /api_user@email.com/
      end

      should "not list web users" do
        create(:user, email: "web_user@email.com")
        get :index
        assert_select "td", count: 0, text: /web_user@email.com/
      end

      should "list applications for api user" do
        application = create(:application, name: "app-name")
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :index

        assert_select "td>span" do |spans|
          apps_span = spans.find { |s| s.text.strip == "Apps" }
          assert_select apps_span.parent, "ul>li", text: "app-name"
        end
      end

      should "not list retired applications for api user" do
        application = create(:application, name: "app-name", retired: true)
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :index

        assert_select "td>span" do |spans|
          apps_span = spans.find { |s| s.text.strip == "Apps" }
          assert_select apps_span.parent, "ul>li", text: "app-name", count: 0
        end
      end

      should "list API-only applications for api user" do
        application = create(:application, name: "app-name", api_only: true)
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :index

        assert_select "td>span" do |spans|
          apps_span = spans.find { |s| s.text.strip == "Apps" }
          assert_select apps_span.parent, "ul>li", text: "app-name"
        end
      end
    end

    context "POST create" do
      should "create a new API user" do
        assert_difference "ApiUser.count", 1 do
          post :create, params: { api_user: { name: "Content Store Application", email: "content.store@gov.uk" } }
        end
      end

      should "log API user created event in the api users event log" do
        EventLog.stubs(:record_event) # to ignore logs being created, other than the one under test
        EventLog.expects(:record_event).with(instance_of(ApiUser), EventLog::API_USER_CREATED, initiator: @superadmin, ip_address: request.remote_ip)
        post :create, params: { api_user: { name: "Content Store Application", email: "content.store@gov.uk" } }
      end

      should "redisplay the form with errors if save fails" do
        post :create, params: { api_user: { name: "Content Store Application", email: "content.store at gov uk" } }

        assert_template :new
        assert_select "div.govuk-error-summary", /Email is invalid/
      end
    end

    context "GET edit" do
      setup do
        @api_user = create(:api_user)
      end

      should "show the form for editing an API user" do
        get :edit, params: { id: @api_user }

        assert_select "form[action='#{api_user_path(@api_user)}']" do
          assert_select "input[name='api_user[name]'][value='#{@api_user.name}']"
          assert_select "input[name='api_user[email]'][value='#{@api_user.email}']"
        end
      end
    end

    context "GET manage_permissions" do
      setup do
        @api_user = create(:api_user)
      end

      should "allow editing permissions for application which user has access to" do
        application = create(:application, name: "app-name", with_supported_permissions: %w[edit])
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :manage_permissions, params: { id: api_user.id }

        assert_select "table#editable-permissions tr" do
          assert_select "td", text: "app-name"
          assert_select "td" do
            assert_select "select[name='api_user[supported_permission_ids][]']" do
              assert_select "option", text: "edit"
            end
          end
        end
      end

      should "not allow editing permissions for application which user does not have access to" do
        application = create(:application, name: "app-name", with_supported_permissions: %w[edit])
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })

        get :manage_permissions, params: { id: api_user.id }

        assert_select "table#editable-permissions", count: 0
      end

      should "not allow editing permissions for retired application" do
        application = create(:application, name: "retired-app-name", retired: true)
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :manage_permissions, params: { id: api_user.id }

        assert_select "table#editable-permissions", count: 0
      end

      should "allow editing permissions for API-only application" do
        application = create(:application, name: "api-only-app-name", api_only: true)
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        get :manage_permissions, params: { id: api_user.id }

        assert_select "table#editable-permissions tr" do
          assert_select "td", text: "api-only-app-name"
        end
      end
    end

    context "GET manage_tokens" do
      setup do
        @api_user = create(:api_user)
      end

      should "show API user's access tokens" do
        application = create(:application)
        token = create(:access_token, resource_owner_id: @api_user.id, application:)

        get :manage_tokens, params: { id: @api_user }

        assert_select "table#authorisations tbody td", text: application.name do |td|
          assert_select td.first.parent, "code", text: /^#{token[0..7]}/
        end
      end

      should "show button for regenerating API user's access token for an application" do
        application = create(:application)
        token = create(:access_token, resource_owner_id: @api_user.id, application:)

        get :manage_tokens, params: { id: @api_user }

        regenerate_token_path = revoke_api_user_authorisation_path(@api_user, token, regenerate: true)

        assert_select "table#authorisations tbody td", text: application.name do |td|
          assert_select td.first.parent, "form[action='#{regenerate_token_path}']" do
            assert_select "input[type='submit']", value: "Re-generate"
          end
        end
      end

      should "show button for revoking API user's access token for an application" do
        application = create(:application)
        token = create(:access_token, resource_owner_id: @api_user.id, application:)

        get :manage_tokens, params: { id: @api_user }

        revoke_token_path = revoke_api_user_authorisation_path(@api_user, token)

        assert_select "table#authorisations tbody td", text: application.name do |td|
          assert_select td.first.parent, "form[action='#{revoke_token_path}']" do
            assert_select "input[type='submit']", value: "Revoke"
          end
        end
      end

      should "not show API user's revoked access tokens" do
        application = create(:application)
        create(:access_token, resource_owner_id: @api_user.id, application:, revoked_at: Time.current)

        get :manage_tokens, params: { id: @api_user }

        assert_select "table#authorisations tbody td", text: application.name, count: 0
      end

      should "not show API user's access tokens for retired applications" do
        application = create(:application, retired: true)
        create(:access_token, resource_owner_id: @api_user.id, application:)

        get :manage_tokens, params: { id: @api_user }

        assert_select "table#authorisations tbody td", text: application.name, count: 0
      end
    end

    context "PUT update" do
      should "update the user" do
        api_user = create(:api_user, name: "Old Name")

        put :update, params: { id: api_user.id, api_user: { name: "New Name" } }

        assert_equal "New Name", api_user.reload.name
        assert_redirected_to :api_users
        assert_equal "Updated API user #{api_user.email} successfully", flash[:notice]
      end

      should "update the user's permissions" do
        application = create(:application, name: "app-name", with_supported_permissions: %w[edit])
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        signin_permission = application.supported_permissions.find_by(name: SupportedPermission::SIGNIN_NAME)
        edit_permission = application.supported_permissions.find_by(name: "edit")
        permissions = [signin_permission, edit_permission]

        put :update, params: { id: api_user.id, api_user: { supported_permission_ids: permissions } }

        assert_same_elements permissions, api_user.reload.supported_permissions
      end

      should "update the user's permissions for API-only app" do
        application = create(:application, name: "app-name", with_supported_permissions: %w[edit], api_only: true)
        api_user = create(:api_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
        create(:access_token, resource_owner_id: api_user.id, application:)

        signin_permission = application.supported_permissions.find_by(name: SupportedPermission::SIGNIN_NAME)
        edit_permission = application.supported_permissions.find_by(name: "edit")
        permissions = [signin_permission, edit_permission]

        put :update, params: { id: api_user.id, api_user: { supported_permission_ids: permissions } }

        assert_same_elements permissions, api_user.reload.supported_permissions
      end

      should "redisplay the form with errors if save fails" do
        api_user = create(:api_user)

        put :update, params: { id: api_user.id, api_user: { name: "" } }

        assert_template :edit
        assert_select "div.alert ul li", "Name can't be blank"
      end

      should "push permission changes out to apps" do
        api_user = create(:api_user)

        PermissionUpdater.expects(:perform_on).with(api_user).once

        put :update,
            params: {
              "id" => api_user.id,
              "api_user" => { "name" => api_user.name,
                              "email" => api_user.email },
            }
      end
    end
  end
end
