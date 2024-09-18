require "test_helper"

class Account::SigninPermissionsControllerTest < ActionController::TestCase
  context "#create" do
    should "prevent unauthenticated users" do
      application = create(:application)

      post :create, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        post :create, params: { application_id: application.id }
      end
    end

    should "assign the success alert hash to flash" do
      current_user = create(:admin_user)
      sign_in current_user

      application = create(:application)

      stub_policy(
        current_user,
        Doorkeeper::Application,
        policy_class: Account::ApplicationPolicy,
        grant_signin_permission?: true,
      )

      Account::SigninPermissionsController
        .any_instance
        .expects(:access_granted_description)
        .with(application.id).returns("Granted access to myself")

      post :create, params: { application_id: application.id }

      expected = { message: "Access granted", description: "Granted access to myself" }
      assert_equal expected, flash[:success_alert]
    end
  end

  context "#delete" do
    should "prevent unauthenticated users" do
      application = create(:application)

      get :delete, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :delete, params: { application_id: application.id }
      end
    end
  end

  context "#destroy" do
    should "assign the success alert hash to flash" do
      current_user = create(:admin_user)
      sign_in current_user

      application = create(:application)
      current_user.grant_application_signin_permission(application)

      stub_policy(
        current_user,
        application,
        policy_class: Account::ApplicationPolicy,
        remove_signin_permission?: true,
      )

      Account::SigninPermissionsController
        .any_instance
        .expects(:access_removed_description)
        .with(application.id).returns("Removed access from myself")

      delete :destroy, params: { application_id: application.id }

      expected = { message: "Access removed", description: "Removed access from myself" }
      assert_equal expected, flash[:success_alert]
    end

    should "prevent unauthenticated users" do
      application = create(:application)

      delete :destroy, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        delete :destroy, params: { application_id: application.id }
      end
    end
  end
end
