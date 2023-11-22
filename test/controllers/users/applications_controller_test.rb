require "test_helper"

class Users::ApplicationsControllerTest < ActionController::TestCase
  context "#index" do
    context "logged in as a GOV.UK admin" do
      setup do
        @user = create(:admin_user)
        @target_user = create(:user)
      end

      should "display the button to grant access to an application" do
        application = create(:application, name: "app-name")
        sign_in @user

        get :index, params: { user_id: @target_user }

        assert_select "tr td", text: "app-name"
        assert_select "form[action='#{account_application_signin_permission_path(application)}']"
      end

      should "display the button to remove access to an application" do
        application = create(:application, name: "app-name")
        @user.grant_application_signin_permission(application)
        sign_in @user

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "a[href='#{delete_account_application_signin_permission_path(application)}']"
      end

      should "display a link to update permissions when the application has more than just a signin permission" do
        application = create(:application, name: "app-name", with_supported_permissions: %w[permission])
        @user.grant_application_signin_permission(application)
        sign_in @user

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "a[href='#{edit_account_application_permissions_path(application)}']"
      end

      should "not display a link to update permissions when the application has just a signin permission" do
        application = create(:application, name: "app-name")
        @user.grant_application_signin_permission(application)
        sign_in @user

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "a[href='#{edit_account_application_permissions_path(application)}']", count: 0
      end

      should "not display a retired application" do
        create(:application, name: "retired-app-name", retired: true)
        sign_in @user

        get :index

        assert_select "tr td", text: "retired-app-name", count: 0
      end

      should "not display an API-only application" do
        create(:application, name: "api-only-app-name", api_only: true)
        sign_in @user

        get :index

        assert_select "tr td", text: "api-only-app-name", count: 0
      end
    end

    context "logged in as a publishing manager" do
      setup do
        @application = create(:application, name: "app-name")
        @user = create(:organisation_admin_user)
      end

      should "not display the button to grant access to an application" do
        sign_in @user

        get :index

        assert_select "tr td", text: "app-name"
        assert_select "form[action='#{account_application_signin_permission_path(@application)}']", count: 0
      end

      context "when the user has signin permissions for the application" do
        setup do
          @user.grant_application_signin_permission(@application)
        end

        should "display the button to remove access to an application" do
          sign_in @user

          get :index

          assert_select "tr td", text: "app-name"
          assert_select "a[href='#{delete_account_application_signin_permission_path(@application)}']"
        end

        should "display a link to update permissions when the application has more than just a signin permission" do
          create(:supported_permission, application: @application, name: "permission")

          sign_in @user

          get :index

          assert_select "tr td", text: "app-name"
          assert_select "a[href='#{edit_account_application_permissions_path(@application)}']"
        end

        should "not display a link to update permissions when the application has just a signin permission" do
          sign_in @user

          get :index

          assert_select "tr td", text: "app-name"
          assert_select "a[href='#{edit_account_application_permissions_path(@application)}']", count: 0
        end

        context "when the application does not have a delegatable signin permission" do
          setup do
            @application.signin_permission.update!(delegatable: false)
          end

          should "not display the button to remove access to an application" do
            sign_in @user

            get :index

            assert_select "tr td", text: "app-name"
            assert_select "a[href='#{delete_account_application_signin_permission_path(@application)}']", count: 0
          end

          should "display a link to view permissions" do
            sign_in @user

            get :index

            assert_select "tr td", text: "app-name"
            assert_select "a[href='#{account_application_permissions_path(@application)}']"
          end
        end
      end
    end
  end
end
