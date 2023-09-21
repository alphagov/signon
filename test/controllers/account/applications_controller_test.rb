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

  context "#index" do
    context "logged in as a publishing manager" do
      should "not display the button to grant access to an application" do
        application = create(:application, name: "app-name")
        sign_in create(:organisation_admin_user)

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "form[action='#{account_application_signin_permission_path(application)}']", count: 0
      end
    end
  end
end
