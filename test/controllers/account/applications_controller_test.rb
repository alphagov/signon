require "test_helper"

class Account::ApplicationsControllerTest < ActionController::TestCase
  context "#show" do
    setup do
      @application = create(:application)
    end

    should "prevent unauthenticated users" do
      get :show, params: { id: @application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "redirect authenticated users to /accounts/applications" do
      user = create(:admin_user)

      sign_in user

      get :show, params: { id: @application.id }

      assert_redirected_to "/account/applications"
    end
  end
end
