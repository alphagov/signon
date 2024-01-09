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
        @api_user = create(:api_user, name: "api-user-name", email: "api-user@gov.uk")
      end

      should "display the API user's name and a link to change the name" do
        get :edit, params: { id: @api_user }

        assert_select "*", text: /Name\s+api-user-name/
        assert_select "a[href='#{edit_api_user_name_path(@api_user)}']", text: /Change\s+Name/
      end

      should "display the API user's email and a link to change the name" do
        get :edit, params: { id: @api_user }

        assert_select "*", text: /Email\s+api-user@gov.uk/
        assert_select "a[href='#{edit_api_user_email_path(@api_user)}']", text: /Change\s+Email/
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

        assert_select ".govuk-summary-card__title", text: application.name do |divs|
          assert_select divs.first.parent.parent, "code", text: /^#{token[0..7]}/
        end
      end

      should "show link for revoking API user's access token for an application" do
        application = create(:application)
        token = create(:access_token, resource_owner_id: @api_user.id, application:)

        get :manage_tokens, params: { id: @api_user }

        edit_token_path = edit_api_user_authorisation_path(@api_user, token)

        assert_select "a[href='#{edit_token_path}']", text: "Revoke token giving #{@api_user.name} access to #{application.name}"
      end

      should "not show API user's revoked access tokens" do
        application = create(:application)
        create(:access_token, resource_owner_id: @api_user.id, application:, revoked_at: Time.current)

        get :manage_tokens, params: { id: @api_user }

        assert_select ".govuk-summary-card__title", text: application.name, count: 0
      end

      should "not show API user's access tokens for retired applications" do
        application = create(:application, retired: true)
        create(:access_token, resource_owner_id: @api_user.id, application:)

        get :manage_tokens, params: { id: @api_user }

        assert_select ".govuk-summary-card__title", text: application.name, count: 0
      end
    end
  end
end
