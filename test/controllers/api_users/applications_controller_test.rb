require "test_helper"

class ApiUsers::ApplicationsControllerTest < ActionController::TestCase
  context "#index" do
    should "prevent unauthenticated users" do
      api_user = create(:api_user)

      get :index, params: { api_user_id: api_user }

      assert_not_authenticated
    end

    should "prevent unauthorised users" do
      api_user = create(:api_user)

      current_user = create(:superadmin_user)
      sign_in current_user

      stub_policy current_user, api_user, index?: false

      get :index, params: { api_user_id: api_user }

      assert_not_authorised
    end

    should "display the applications the api user has access to" do
      api_user = create(:api_user)
      application = create(:application, name: "app-name")
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links(current_user)
      stub_policy current_user, api_user, index?: true

      get :index, params: { api_user_id: api_user }

      assert_select "table:has( > caption[text()='Apps #{api_user.name} has access to'])" do
        assert_select "tr td", text: /app-name/
      end
    end

    should "not include applications where the access token has been revoked" do
      api_user = create(:api_user)
      application = create(:application, name: "revoked-app-name")
      create(:access_token, application:, resource_owner_id: api_user.id, revoked_at: Time.current)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links(current_user)
      stub_policy current_user, api_user, index?: true

      get :index, params: { api_user_id: api_user }

      assert_select "tr td", text: /revoked-app-name/, count: 0
    end

    should "not display a retired application" do
      api_user = create(:api_user)
      application = create(:application, name: "retired-app-name", retired: true)
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links(current_user)
      stub_policy current_user, api_user, index?: true

      get :index, params: { api_user_id: api_user }

      assert_select "tr td", text: /retired-app-name/, count: 0
    end

    should "display a flash message showing the permissions the user has" do
      api_user = create(:api_user)
      application = create(:application, name: "app-name", with_supported_permissions: %w[foo])
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, api_user, index?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { api_user_id: api_user }, flash: { application_id: application.id }

      assert_select ".govuk-notification-banner--success"
    end

    should "not display a link to edit permissions if the user is authorised to edit permissions but the app only has the signin permission" do
      api_user = create(:api_user)
      application = create(:application, name: "app-name")
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, api_user, index?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { api_user_id: api_user }

      assert_select "a[href='#{edit_api_user_application_permissions_path(api_user, application)}']", count: 0
    end

    should "display a link to edit permissions if the user is authorised to edit permissions" do
      api_user = create(:api_user)
      application = create(:application, name: "app-name", with_supported_permissions: %w[foo])
      create(:access_token, application:, resource_owner_id: api_user.id)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, api_user, index?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { api_user_id: api_user }

      assert_select "a[href='#{edit_api_user_application_permissions_path(api_user, application)}']", text: "Update permissions for app-name"
    end
  end
end
