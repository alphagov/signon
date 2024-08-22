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

    should "prevent unauthorised users" do
      user = create(:user)
      sign_in user

      stub_policy user, [:account, Doorkeeper::Application], show?: false

      get :show, params: { id: @application.id }

      assert_not_authorised
    end

    should "redirect authenticated users to the index path" do
      user = create(:user)
      sign_in user

      stub_policy user, [:account, Doorkeeper::Application], show?: true

      get :show, params: { id: @application.id }

      assert_redirected_to "/account/applications"
    end
  end

  context "#index" do
    should "prevent unauthenticated users" do
      get :index

      assert_redirected_to "/users/sign_in"
    end

    should "prevent users who are unauthorised to view the page" do
      user = create(:user)
      sign_in user

      stub_policy user, [:account, Doorkeeper::Application], index?: false

      get :index

      assert_not_authorised
    end

    context "when authenticated and authorised to view the page" do
      setup do
        @user = create(:user)
        sign_in @user

        stub_policy @user, [:account, Doorkeeper::Application], index?: true

        @application = create(:application, name: "app-name")
      end

      context "for apps the user doesn't have access to" do
        should "display the applications, excluding those which are retired or API-only" do
          create(:application, name: "retired-app-name", retired: true)
          create(:application, name: "api-only-app-name", api_only: true)

          get :index

          assert_select "table:has( > caption[text()='Apps you don\\'t have access to'])" do
            assert_select "tr td", text: /app-name/
            assert_select "tr td", text: /retired-app-name/, count: 0
            assert_select "tr td", text: /api-only-app-name/, count: 0
          end
        end

        context "when authorised to grant access" do
          should "display a grant access button" do
            stub_policy @user, [:account, Doorkeeper::Application], index?: true, grant_signin_permission?: true

            get :index

            assert_template :index
            assert_select "form[action='#{account_application_signin_permission_path(@application)}']"
          end
        end

        context "when not authorised to grant access" do
          should "not display a grant access button" do
            stub_policy @user, [:account, Doorkeeper::Application], index?: true, grant_signin_permission?: false

            get :index

            assert_select "form[action='#{account_application_signin_permission_path(@application)}']", count: 0
          end
        end
      end

      context "for apps the user does have access to" do
        setup { @user.grant_application_signin_permission(@application) }

        should "display the applications, excluding those which are retired or API-only" do
          retired_app = create(:application, name: "retired-app-name", retired: true)
          api_only_app = create(:application, name: "api-only-app-name", api_only: true)
          @user.grant_application_signin_permission(retired_app)
          @user.grant_application_signin_permission(api_only_app)

          stub_policy @user, [:account, @application]

          get :index

          assert_select "table:has( > caption[text()='Apps you have access to'])" do
            assert_select "tr td", text: /app-name/
            assert_select "tr td", text: /retired-app-name/, count: 0
            assert_select "tr td", text: /api-only-app-name/, count: 0
          end
        end

        context "removing access" do
          should "display a remove access button when authorised" do
            stub_policy @user, [:account, @application], remove_signin_permission?: true

            get :index

            assert_select "a[href='#{delete_account_application_signin_permission_path(@application)}']"
          end

          should "not display a remove access button when not authorised" do
            stub_policy @user, [:account, @application], remove_signin_permission?: false

            get :index

            assert_select "a[href='#{delete_account_application_signin_permission_path(@application)}']", count: 0
          end
        end

        context "editing permissions" do
          context "when the app only has the signin permission" do
            %w[govuk_admin publishing_manager].each do |role_group|
              context "as a #{role_group}" do
                setup { @user.stubs(:"#{role_group}?").returns(true) }

                should "only display a link to view permissions when authorised to view or edit permissions" do
                  stub_policy @user, [:account, @application], view_permissions?: true, edit_permissions?: true

                  get :index

                  assert_select "a[href='#{edit_account_application_permissions_path(@application)}']", count: 0
                  assert_select "a[href='#{account_application_permissions_path(@application)}']"
                end

                should "not display links to view or edit permissions when not authorised to view permissions" do
                  stub_policy @user, [:account, @application], view_permissions?: false, edit_permissions?: true

                  get :index

                  assert_select "a[href='#{edit_account_application_permissions_path(@application)}']", count: 0
                  assert_select "a[href='#{account_application_permissions_path(@application)}']", count: 0
                end
              end
            end
          end

          context "when the app has non-signin permissions" do
            setup { create(:supported_permission, application: @application) }

            should "display links to view and edit permissions when authorised to view and edit permissions" do
              stub_policy @user, [:account, @application], view_permissions?: true, edit_permissions?: true

              get :index

              assert_select "a[href='#{edit_account_application_permissions_path(@application)}']"
              assert_select "a[href='#{account_application_permissions_path(@application)}']"
            end

            should "only display a link to edit permissions when authorised to edit but not view permissions" do
              stub_policy @user, [:account, @application], view_permissions?: false, edit_permissions?: true

              get :index

              assert_select "a[href='#{edit_account_application_permissions_path(@application)}']"
              assert_select "a[href='#{account_application_permissions_path(@application)}']", count: 0
            end

            should "only display a link to view permissions when not authorised to edit permissions" do
              stub_policy @user, [:account, @application], view_permissions?: true, edit_permissions?: false

              get :index

              assert_select "a[href='#{edit_account_application_permissions_path(@application)}']", count: 0
              assert_select "a[href='#{account_application_permissions_path(@application)}']"
            end
          end
        end
      end
    end
  end
end
