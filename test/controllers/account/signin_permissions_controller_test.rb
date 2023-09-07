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
  end
end
