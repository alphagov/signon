require "test_helper"

class Users::ApplicationsControllerTest < ActionController::TestCase
  def view_permissions_link
    {
      selector: "a[href='#{user_application_permissions_path(@user, @application)}']",
      text: "View permissions for #{@application.name}",
    }
  end

  def edit_permissions_link
    {
      selector: "a[href='#{edit_user_application_permissions_path(@user, @application)}']",
      text: "Update permissions for #{@application.name}",
    }
  end

  def assert_view_permissions_link
    assert_select(view_permissions_link[:selector], text: view_permissions_link[:text])
  end

  def assert_no_view_permissions_link
    assert_select(view_permissions_link[:selector], text: view_permissions_link[:text], count: 0)
  end

  def assert_edit_permissions_link
    assert_select(edit_permissions_link[:selector], text: edit_permissions_link[:text])
  end

  def assert_no_edit_permissions_link
    assert_select(edit_permissions_link[:selector], text: edit_permissions_link[:text], count: 0)
  end

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

      stub_policy(
        current_user,
        { user: @user },
        policy_class: Users::ApplicationPolicy,
        show?: false,
      )

      get :show, params: { user_id: @user, id: @application.id }

      assert_not_authorised
    end

    should "redirect authorised users to the index path" do
      current_user = create(:user)
      sign_in current_user

      stub_policy(
        current_user,
        { user: @user },
        policy_class: Users::ApplicationPolicy,
        show?: true,
      )

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

    should "prevent unauthorised users" do
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy(
        current_user,
        { user: },
        policy_class: Users::ApplicationPolicy,
        index?: false,
      )

      get :index, params: { user_id: user }

      assert_not_authorised
    end

    context "when authenticated and authorised" do
      setup do
        @current_user = create(:user)
        stub_policy_for_navigation_links @current_user
        sign_in @current_user

        @user = create(:user)

        stub_policy(
          @current_user,
          { user: @user },
          policy_class: Users::ApplicationPolicy,
          index?: true,
        )

        @application = create(:application, name: "app-name")

        stub_policy(
          @current_user,
          { application: @application, user: @user },
          policy_class: Users::ApplicationPolicy,
        )
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

        context "viewing and editing permissions" do
          context "when there is only a signin permisson" do
            %w[govuk_admin publishing_manager].each do |role_group|
              context "as a #{role_group}" do
                setup { @current_user.stubs(:"#{role_group}?").returns(true) }

                context "when authorised to view and edit" do
                  should "display only a link to view permissions" do
                    stub_policy(
                      @current_user,
                      { application: @application, user: @user },
                      policy_class: Users::ApplicationPolicy,
                      edit_permissions?: true,
                      view_permissions?: true,
                    )

                    get :index, params: { user_id: @user }

                    assert_view_permissions_link
                    assert_no_edit_permissions_link
                  end
                end

                context "when authorised to view but not edit" do
                  should "display only a link to view permissions" do
                    stub_policy(
                      @current_user,
                      { application: @application, user: @user },
                      policy_class: Users::ApplicationPolicy,
                      edit_permissions?: false,
                      view_permissions?: true,
                    )

                    get :index, params: { user_id: @user }

                    assert_view_permissions_link
                    assert_no_edit_permissions_link
                  end
                end

                context "when authorised to edit but not view" do
                  should "display no links" do
                    stub_policy(
                      @current_user,
                      { application: @application, user: @user },
                      policy_class: Users::ApplicationPolicy,
                      edit_permissions?: true,
                      view_permissions?: false,
                    )

                    get :index, params: { user_id: @user }

                    assert_no_view_permissions_link
                    assert_no_edit_permissions_link
                  end
                end

                context "when not authorised to edit or view" do
                  should "display no links" do
                    stub_policy(
                      @current_user,
                      { application: @application, user: @user },
                      policy_class: Users::ApplicationPolicy,
                      edit_permissions?: false,
                      view_permissions?: false,
                    )

                    get :index, params: { user_id: @user }

                    assert_no_view_permissions_link
                    assert_no_edit_permissions_link
                  end
                end
              end
            end
          end

          context "when there are non-signin permissons" do
            setup { create(:supported_permission, application: @application) }

            context "when authorised to view and edit" do
              should "display links to view and edit permissions" do
                stub_policy(
                  @current_user,
                  { application: @application, user: @user },
                  policy_class: Users::ApplicationPolicy,
                  edit_permissions?: true,
                  view_permissions?: true,
                )

                get :index, params: { user_id: @user }

                assert_view_permissions_link
                assert_edit_permissions_link
              end
            end

            context "when authorised to view but not edit" do
              should "display only a link to view permissions" do
                stub_policy(
                  @current_user,
                  { application: @application, user: @user },
                  policy_class: Users::ApplicationPolicy,
                  edit_permissions?: false,
                  view_permissions?: true,
                )

                get :index, params: { user_id: @user }

                assert_view_permissions_link
                assert_no_edit_permissions_link
              end
            end

            context "when authorised to edit but not view" do
              should "display only a link to edit permissions" do
                stub_policy(
                  @current_user,
                  { application: @application, user: @user },
                  policy_class: Users::ApplicationPolicy,
                  edit_permissions?: true,
                  view_permissions?: false,
                )

                get :index, params: { user_id: @user }

                assert_no_view_permissions_link
                assert_edit_permissions_link
              end
            end

            context "when not authorised to edit or view" do
              should "display no links" do
                stub_policy(
                  @current_user,
                  { application: @application, user: @user },
                  policy_class: Users::ApplicationPolicy,
                  edit_permissions?: false,
                  view_permissions?: false,
                )

                get :index, params: { user_id: @user }

                assert_no_view_permissions_link
                assert_no_edit_permissions_link
              end
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
