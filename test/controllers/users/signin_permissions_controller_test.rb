require "test_helper"

class Users::SigninPermissionsControllerTest < ActionController::TestCase
  context "#create" do
    should "call the UserUpdate service to grant the user access to the application" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, create?: true

      expected_params = { supported_permission_ids: [application.signin_permission.id] }
      user_update = stub("user-update").responds_like_instance_of(UserUpdate)
      user_update.expects(:call)
      UserUpdate.stubs(:new).with(user, expected_params, current_user, anything).returns(user_update)

      post :create, params: { user_id: user, application_id: application.id }
    end

    should "redirect to the edit user path" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, create?: true

      post :create, params: { user_id: user, application_id: application.id }

      assert_redirected_to user_applications_path(user)
    end

    should "prevent unauthenticated users" do
      user = create(:user)
      application = create(:application)

      post :create, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "not authorize access if UserApplicationPermissionPolicy#create? returns false" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, create?: false

      post :create, params: { user_id: user, application_id: application.id }

      assert_not_authorised
    end

    should "raise exception is user isn't found" do
      sign_in create(:admin_user)

      application = create(:application)

      assert_raises(ActiveRecord::RecordNotFound) do
        post :create, params: { user_id: "non-existent-user-id", application_id: application.id }
      end
    end

    should "exclude retired applications" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application, retired: true)

      stub_policy current_user, UserApplicationPermission, create?: true

      assert_raises(ActiveRecord::RecordNotFound) do
        post :create, params: { user_id: user, application_id: application.id }
      end
    end
  end

private

  def stub_user_application_permission(user, application)
    permission = UserApplicationPermission.new
    UserApplicationPermission.stubs(:for).with(user, application).returns(permission)
    permission
  end
end
