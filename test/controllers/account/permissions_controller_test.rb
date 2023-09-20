require "test_helper"

class Account::PermissionsControllerTest < ActionController::TestCase
  context "#index" do
    should "prevent unauthenticated users" do
      application = create(:application)

      get :index, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude permissions that aren't grantable from the UI" do
      application = create(:application,
                           with_supported_permissions: %w[perm-1],
                           with_supported_permissions_not_grantable_from_ui: %w[perm-2])
      user = create(:admin_user, with_signin_permissions_for: [application])

      sign_in user

      get :index, params: { application_id: application.id }

      assert_select "td", text: "perm-1"
      assert_select "td", text: "perm-2", count: 0
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :index, params: { application_id: application.id }
      end
    end

    should "order permissions by whether the user has access and then alphabetically" do
      application = create(:application,
                           with_supported_permissions: %w[aaa bbb ttt uuu])
      user = create(:admin_user,
                    with_signin_permissions_for: [application],
                    with_permissions: { application => %w[aaa ttt] })

      sign_in user

      get :index, params: { application_id: application.id }

      assert_equal %w[signin aaa ttt bbb uuu], assigns(:permissions).map(&:name)
    end
  end
end
