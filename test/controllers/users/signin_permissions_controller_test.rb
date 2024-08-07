require "test_helper"

class Users::SigninPermissionsControllerTest < ActionController::TestCase
  context "#create" do
    should "call the UserUpdate service to grant the user access to the application" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        grant_signin_permission?: true,
      )

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

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        grant_signin_permission?: true,
      )

      post :create, params: { user_id: user, application_id: application.id }

      assert_redirected_to user_applications_path(user)
    end

    should "prevent unauthenticated users" do
      user = create(:user)
      application = create(:application)

      post :create, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorised users" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        grant_signin_permission?: false,
      )

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

      assert_raises(ActiveRecord::RecordNotFound) do
        post :create, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application, api_only: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        post :create, params: { user_id: user, application_id: application.id }
      end
    end
  end

  context "#delete" do
    should "have a button to confirm deletion of the user when current_user is authorized to delete" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)
      user.grant_application_signin_permission(application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: true,
      )

      get :delete, params: { user_id: user, application_id: application.id }

      assert_template :delete
      assert_select "form[action='#{user_application_signin_permission_path(user, application)}']" do
        assert_select "button[type='submit']", text: "Confirm"
        assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
      end
    end

    should "prevent unauthenticated users" do
      user = create(:user)
      application = create(:application)

      get :delete, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent authorised users" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)
      user.grant_application_signin_permission(application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: false,
      )

      get :delete, params: { user_id: user, application_id: application.id }

      assert_not_authorised
    end

    should "raise exception if user isn't found" do
      sign_in create(:admin_user)

      application = create(:application)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :delete, params: { user_id: "non-existent-user-id", application_id: application.id }
      end
    end

    should "raise exception if user doesn't have the signin permission for the app" do
      sign_in create(:admin_user)

      user = create(:user)
      application = create(:application)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :delete, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      user = create(:user)
      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :delete, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      user = create(:user)
      application = create(:application, api_only: true)
      user.grant_application_signin_permission(application)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :delete, params: { user_id: user, application_id: application.id }
      end
    end
  end

  context "#destroy" do
    should "call the UserUpdate service to remove the user's access to the application" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)
      user.grant_application_signin_permission(application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: true,
      )

      expected_params = { supported_permission_ids: [] }
      user_update = stub("user-update").responds_like_instance_of(UserUpdate)
      user_update.expects(:call)
      UserUpdate.stubs(:new).with(user, expected_params, current_user, anything).returns(user_update)

      delete :destroy, params: { user_id: user, application_id: application.id }
    end

    should "redirect to the edit user path" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)
      user.grant_application_signin_permission(application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: true,
      )

      delete :destroy, params: { user_id: user, application_id: application.id }

      assert_redirected_to user_applications_path(user)
    end

    should "prevent unauthenticated users" do
      user = create(:user)
      application = create(:application)

      delete :destroy, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorised users" do
      current_user = create(:admin_user)
      sign_in current_user

      user = create(:user)
      application = create(:application)
      user.grant_application_signin_permission(application)

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        remove_signin_permission?: false,
      )

      delete :destroy, params: { user_id: user, application_id: application.id }

      assert_not_authorised
    end

    should "raise exception is user isn't found" do
      sign_in create(:admin_user)

      application = create(:application)

      assert_raises(ActiveRecord::RecordNotFound) do
        delete :destroy, params: { user_id: "non-existent-user-id", application_id: application.id }
      end
    end

    should "raise exception is user doesn't have the signin permission for the app" do
      sign_in create(:admin_user)

      user = create(:user)
      application = create(:application)

      assert_raises(ActiveRecord::RecordNotFound) do
        delete :destroy, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      user = create(:user)
      application = create(:application, retired: true)
      user.grant_application_signin_permission(application)

      assert_raises(ActiveRecord::RecordNotFound) do
        delete :destroy, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      user = create(:user)
      application = create(:application, api_only: true)
      user.grant_application_signin_permission(application)

      assert_raises(ActiveRecord::RecordNotFound) do
        delete :destroy, params: { user_id: user, application_id: application.id }
      end
    end
  end
end
