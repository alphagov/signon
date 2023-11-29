require "test_helper"

class Users::ApplicationsControllerTest < ActionController::TestCase
  context "#show" do
    setup do
      @application = create(:application)
    end

    should "prevent unauthenticated users" do
      user = create(:user)

      get :show, params: { user_id: user, id: @application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorised users" do
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: false

      get :show, params: { user_id: user, id: @application.id }

      assert_not_authorised
    end

    should "redirect authorised users to /accounts/applications" do
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: true

      get :show, params: { user_id: user, id: @application.id }

      assert_redirected_to user_applications_path(user)
    end
  end

  context "#index" do
    should "prevent unauthenticated users" do
      user = create(:user)

      get :index, params: { user_id: user }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorised users" do
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: false

      get :index, params: { user_id: user }

      assert_not_authorised
    end

    should "display the applications the user has access to" do
      user = create(:user)
      application = create(:application, name: "app-name")
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { user_id: user }

      assert_select "table:has( > caption[text()='Apps #{user.name} has access to'])" do
        assert_select "tr td", text: "app-name"
      end
    end

    should "display the applications the user does not have access to" do
      user = create(:user)
      create(:application, name: "app-name")

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { user_id: user }

      heading_id = css_select("h2:contains('Apps #{user.name} does not have access to')").attribute("id").value
      assert_select "table[aria-labelledby='#{heading_id}']" do
        assert_select "tr td", text: "app-name"
      end
    end

    should "not display a retired application" do
      user = create(:user)
      create(:application, name: "retired-app-name", retired: true)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { user_id: user }

      assert_select "tr td", text: "retired-app-name", count: 0
    end

    should "not display an API-only application" do
      user = create(:user)
      create(:application, name: "api-only-app-name", api_only: true)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: true
      stub_policy_for_navigation_links current_user

      get :index, params: { user_id: user }

      assert_select "tr td", text: "api-only-app-name", count: 0
    end
  end

private

  def stub_policy_for_navigation_links(current_user)
    stub_policy(current_user, User, index?: true)
  end
end
