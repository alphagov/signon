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
    context "logged in as a GOV.UK admin" do
      should "display the button to grant access to an application" do
        application = create(:application, name: "app-name")
        sign_in create(:admin_user)

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "form[action='#{account_application_signin_permission_path(application)}']"
      end

      should "display the button to remove access to an application" do
        application = create(:application, name: "app-name")
        user = create(:admin_user, with_signin_permissions_for: [application])

        sign_in user

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "a[href='#{delete_account_application_signin_permission_path(application)}']"
      end

      should "not display a retired application" do
        create(:application, name: "retired-app-name", retired: true)
        sign_in create(:admin_user)

        get :index

        assert_select "tr td", text: "retired-app-name", count: 0
      end

      should "not display an API-only application" do
        create(:application, name: "api-only-app-name", api_only: true)
        sign_in create(:admin_user)

        get :index

        assert_select "tr td", text: "api-only-app-name", count: 0
      end
    end

    context "logged in as a publishing manager" do
      should "not display the button to grant access to an application" do
        application = create(:application, name: "app-name")
        sign_in create(:organisation_admin_user)

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "form[action='#{account_application_signin_permission_path(application)}']", count: 0
      end

      should "not display the button to remove access to an application" do
        application = create(:application, name: "app-name")
        application.signin_permission.update!(delegatable: false)
        user = create(:organisation_admin_user, with_signin_permissions_for: [application])

        sign_in user

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "a[href='#{delete_account_application_signin_permission_path(application)}']", count: 0
      end
    end
  end
end
