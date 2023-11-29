require "test_helper"

class Users::PermissionsControllerTest < ActionController::TestCase
  context "#show" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      get :show, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude permissions that aren't grantable from the UI" do
      application = create(:application,
                           with_supported_permissions: %w[perm-1],
                           with_supported_permissions_not_grantable_from_ui: %w[perm-2])
      user = create(:user, with_signin_permissions_for: [application])

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links current_user
      stub_policy current_user, user, edit?: true

      get :show, params: { user_id: user, application_id: application.id }

      assert_select "td", text: "perm-1"
      assert_select "td", text: "perm-2", count: 0
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application.id }
      end
    end

    should "order permissions by whether the user has access and then alphabetically" do
      application = create(:application,
                           with_supported_permissions: %w[aaa bbb ttt uuu])
      user = create(:user,
                    with_signin_permissions_for: [application],
                    with_permissions: { application => %w[aaa ttt] })

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links current_user
      stub_policy current_user, user, edit?: true

      get :show, params: { user_id: user, application_id: application.id }

      assert_equal %w[signin aaa ttt bbb uuu], assigns(:permissions).map(&:name)
    end

    should "prevent unauthorised users" do
      application = create(:application)
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: false

      get :show, params: { user_id: user, application_id: application.id }

      assert_not_authorised
    end
  end

private

  def stub_policy_for_navigation_links(current_user)
    stub_policy(current_user, User, index?: true)
  end
end
