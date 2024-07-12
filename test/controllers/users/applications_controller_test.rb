require "test_helper"

class Users::ApplicationsControllerTest < ActionController::TestCase
  context "#show" do
    setup do
      @application = create(:application)
      @user = create(:user)
    end

    should "prevent unauthenticated users" do
      get :show, params: { user_id: @user, id: @application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorised users" do
      current_user = create(:user)
      sign_in current_user

      stub_policy current_user, @user, edit?: false

      get :show, params: { user_id: @user, id: @application.id }

      assert_not_authorised
    end

    should "redirect authorised users to the index path" do
      current_user = create(:user)
      sign_in current_user

      stub_policy current_user, @user, edit?: true

      get :show, params: { user_id: @user, id: @application.id }

      assert_redirected_to user_applications_path(@user)
    end
  end

  context "#index" do
    should "prevent unauthenticated users" do
      user = create(:user)

      get :index, params: { user_id: user }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent users who are unauthorised to edit the user" do
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: false

      get :index, params: { user_id: user }

      assert_not_authorised
    end

    context "when authenticated and authorised to edit the user" do
      setup do
        @current_user = create(:user)
        stub_policy_for_navigation_links @current_user
        sign_in @current_user

        @user = create(:user)
        stub_policy @current_user, @user, edit?: true

        @application = create(:application, name: "app-name")
      end

      context "for apps the user doesn't have access to" do
        should "display the applications" do
          get :index, params: { user_id: @user }

          assert_select "table:has( > caption[text()='Apps #{@user.name} does not have access to'])" do
            assert_select "tr td", text: /app-name/
          end
        end

        context "when authorised to grant access" do
          should "display a grant access button" do
            stub_policy(
              @current_user,
              { application: @application, user: @user },
              policy_class: Users::ApplicationPolicy,
              grant_signin_permission?: true,
            )

            get :index, params: { user_id: @user }

            assert_select "form[action='#{user_application_signin_permission_path(@user, @application)}']"
          end
        end

        context "when not authorised to grant access" do
          should "not display a grant access button" do
            stub_policy(
              @current_user,
              { application: @application, user: @user },
              policy_class: Users::ApplicationPolicy,
              grant_signin_permission?: false,
            )

            get :index, params: { user_id: @user }

            assert_select "form[action='#{user_application_signin_permission_path(@user, @application)}']", count: 0
          end
        end
      end

      context "for apps the user does have access to" do
        setup { @user.grant_application_signin_permission(@application) }

        should "display the applications" do
          get :index, params: { user_id: @user }

          assert_select "table:has( > caption[text()='Apps #{@user.name} has access to'])" do
            assert_select "tr td", text: /app-name/
          end
        end

        context "removing access" do
          should "display a remove access button when authorised" do
            stub_policy(
              @current_user,
              { application: @application, user: @user },
              policy_class: Users::ApplicationPolicy,
              remove_signin_permission?: true,
            )

            get :index, params: { user_id: @user }

            assert_select "a[href='#{delete_user_application_signin_permission_path(@user, @application)}']", text: "Remove access to app-name"
          end

          should "not display a remove access button when not authorised" do
            stub_policy(
              @current_user,
              { application: @application, user: @user },
              policy_class: Users::ApplicationPolicy,
              remove_signin_permission?: false,
            )

            get :index, params: { user_id: @user }

            assert_select "a[href='#{delete_user_application_signin_permission_path(@user, @application)}']", count: 0
          end
        end

        context "editing permissions" do
          context "when the app only has the signin permission" do
            should "only display a link to view permissions" do
              stub_policy(
                @current_user,
                { application: @application, user: @user },
                policy_class: Users::ApplicationPolicy,
                edit_permissions?: true,
              )

              get :index, params: { user_id: @user }

              assert_select "a[href='#{edit_user_application_permissions_path(@user, @application)}']", text: "Update permissions for app-name", count: 0
              assert_select "a[href='#{user_application_permissions_path(@user, @application)}']", text: "View permissions for app-name"
            end
          end

          context "when the app has non-signin permissions" do
            setup { create(:supported_permission, application: @application) }

            should "display links to view and edit permissions when authorised to edit permissions" do
              stub_policy(
                @current_user,
                { application: @application, user: @user },
                policy_class: Users::ApplicationPolicy,
                edit_permissions?: true,
              )

              get :index, params: { user_id: @user }

              assert_select "a[href='#{edit_user_application_permissions_path(@user, @application)}']", text: "Update permissions for app-name"
              assert_select "a[href='#{user_application_permissions_path(@user, @application)}']", text: "View permissions for app-name"
            end

            should "only display a link to view permissions when not authorised to edit permissions" do
              stub_policy(
                @current_user,
                { application: @application, user: @user },
                policy_class: Users::ApplicationPolicy,
                edit_permissions?: false,
              )

              get :index, params: { user_id: @user }

              assert_select "a[href='#{edit_user_application_permissions_path(@user, @application)}']", text: "Update permissions for app-name", count: 0
              assert_select "a[href='#{user_application_permissions_path(@user, @application)}']", text: "View permissions for app-name"
            end
          end
        end
      end

      should "not display a retired application" do
        create(:application, name: "retired-app-name", retired: true)

        get :index, params: { user_id: @user }

        assert_select "tr td", text: /retired-app-name/, count: 0
      end

      should "not display an API-only application" do
        create(:application, name: "api-only-app-name", api_only: true)

        get :index, params: { user_id: @user }

        assert_select "tr td", text: /api-only-app-name/, count: 0
      end
    end
  end
end
