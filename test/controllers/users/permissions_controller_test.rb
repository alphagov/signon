require "test_helper"

class Users::PermissionsControllerTest < ActionController::TestCase
  context "#show" do
    context "when a user can view another's permissions" do
      should "order permissions by whether the user has access and then alphabetically" do
        application = create(:application,
                             with_non_delegatable_supported_permissions: %w[uuu aaa ttt bbb])

        user = create(:user,
                      with_signin_permissions_for: [application],
                      with_permissions: { application => %w[aaa ttt] })

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy_for_navigation_links current_user
        stub_policy current_user, user, edit?: true

        get :show, params: { user_id: user, application_id: application }

        assert_equal %w[signin aaa ttt bbb uuu], assigns(:permissions).map(&:name)
      end

      should "exclude permissions that aren't grantable from the UI" do
        application = create(:application)
        grantable_permission = create(:supported_permission, application:)
        non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

        user = create(:user, with_signin_permissions_for: [application])

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy_for_navigation_links current_user
        stub_policy current_user, user, edit?: true

        get :show, params: { user_id: user, application_id: application }

        assert_select "td", text: grantable_permission.name
        assert_select "td", text: non_grantable_permission.name, count: 0
      end
    end

    context "when a user cannot view another's permissions" do
      should "prevent unauthenticated users" do
        application = create(:application)
        user = create(:user)

        get :show, params: { user_id: user, application_id: application }

        assert_redirected_to "/users/sign_in"
      end

      should "prevent unauthorised users" do
        application = create(:application)
        user = create(:user, with_signin_permissions_for: [application])

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          view_permissions?: false,
        )

        get :show, params: { user_id: user, application_id: application }

        assert_not_authorised
      end

      should "raise an exception if the user doesn't have access to the application" do
        sign_in create(:admin_user)

        application = create(:application)
        user = create(:user)

        assert_raises(ActiveRecord::RecordNotFound) do
          get :show, params: { user_id: user, application_id: application }
        end
      end

      should "raise an exception if the application is retired" do
        sign_in create(:admin_user)

        application = create(:application, retired: true)
        user = create(:user, with_signin_permissions_for: [application])

        assert_raises(ActiveRecord::RecordNotFound) do
          get :show, params: { user_id: user, application_id: application }
        end
      end

      should "raise an exception if the application is API-only" do
        sign_in create(:admin_user)

        application = create(:application, api_only: true)
        user = create(:user, with_signin_permissions_for: [application])

        assert_raises(ActiveRecord::RecordNotFound) do
          get :show, params: { user_id: user, application_id: application }
        end
      end
    end
  end

  context "#edit" do
    context "when a user can edit another's permissions" do
      should "render a page with checkboxes for the grantable permissions and a hidden field for the signin permission so that it is not removed" do
        application = create(:application)
        old_grantable_permission = create(:supported_permission, application:)
        new_grantable_permission = create(:supported_permission, application:)
        new_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

        user = create(
          :user,
          with_signin_permissions_for: [application],
          with_permissions: { application => [old_grantable_permission.name] },
        )

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: true,
        )

        get :edit, params: { user_id: user, application_id: application }

        assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{old_grantable_permission.id}']"
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_grantable_permission.id}']"
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_non_grantable_permission.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
        assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
      end

      context "for apps with greater than eight supported permissions" do
        setup do
          @application = create(:application)
          @old_permissions = create_list(:supported_permission, 2, application: @application)
          @new_permissions = create_list(:supported_permission, 7, application: @application)

          user = create(
            :user,
            with_signin_permissions_for: [@application],
            with_permissions: { @application => @old_permissions.map(&:name) },
          )

          current_user = create(:admin_user)
          sign_in current_user

          stub_policy(
            current_user,
            { application: @application, user: },
            policy_class: Users::ApplicationPolicy,
            edit_permissions?: true,
          )

          get :edit, params: { user_id: user, application_id: @application }
        end

        should "display a select component for grantable but non-existing permissions" do
          assert_select "select[name='application[new_permission_id]']"
        end

        should "include a hidden field representing whether the user wants to add more permissions, defaulting to false" do
          assert_select "input[type='hidden'][name='application[add_more]'][value='false']"
        end

        should "display checkboxes for the existing permissions" do
          @old_permissions.each do |old_permission|
            assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{old_permission.id}']"
          end

          @new_permissions.each do |new_permission|
            assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_permission.id}']", count: 0
          end

          assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@application.signin_permission.id}']", count: 0
        end
      end
    end

    context "when a user cannot edit another's permissions" do
      should "prevent unauthenticated users" do
        application = create(:application)
        user = create(:user)

        get :edit, params: { user_id: user, application_id: application }

        assert_redirected_to "/users/sign_in"
      end

      should "prevent unauthorised users" do
        application = create(:application)
        user = create(:user, with_signin_permissions_for: [application])

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: false,
        )
        get :edit, params: { user_id: user, application_id: application }

        assert_not_authorised
      end

      should "raise an exception if the user doesn't have access to the application" do
        sign_in create(:admin_user)

        application = create(:application)
        user = create(:user)

        assert_raises(ActiveRecord::RecordNotFound) do
          get :edit, params: { user_id: user, application_id: application }
        end
      end

      should "raise an exception if the application is retired" do
        sign_in create(:admin_user)

        application = create(:application, retired: true)
        user = create(:user, with_signin_permissions_for: [application])

        assert_raises(ActiveRecord::RecordNotFound) do
          get :edit, params: { user_id: user, application_id: application }
        end
      end

      should "raise an exception if the application is API-only" do
        sign_in create(:admin_user)

        application = create(:application, api_only: true)
        user = create(:user, with_signin_permissions_for: [application])

        assert_raises(ActiveRecord::RecordNotFound) do
          get :edit, params: { user_id: user, application_id: application }
        end
      end

      should "redirect to the applications path if there are no non-signin applications" do
        application = create(:application)
        user = create(:user, with_signin_permissions_for: [application])

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: true,
        )

        get :edit, params: { user_id: user, application_id: application }

        assert_redirected_to user_applications_path(user)
        assert_equal "No permissions found for #{application.name} that you are authorised to manage.", flash[:alert]
      end

      context "when the current user is a publishing manager" do
        should "redirect to the applications path if there are no delegatable non-signin applications" do
          application = create(:application, with_non_delegatable_supported_permissions: %w[permission])
          user = create(:user, with_signin_permissions_for: [application])

          current_user = create(:user)
          current_user.stubs(:publishing_manager?).returns(true)
          sign_in current_user

          stub_policy(
            current_user,
            { application:, user: },
            policy_class: Users::ApplicationPolicy,
            edit_permissions?: true,
          )

          get :edit, params: { user_id: user, application_id: application }

          assert_redirected_to user_applications_path(user)
          assert_equal "No permissions found for #{application.name} that you are authorised to manage.", flash[:alert]
        end

        should "exclude non-delegatable permissions" do
          application = create(:application)
          old_delegatable_permission = create(:delegatable_supported_permission, application:)
          old_non_delegatable_permission = create(:non_delegatable_supported_permission, application:)
          new_delegatable_permission = create(:delegatable_supported_permission, application:)
          new_non_delegatable_permission = create(:non_delegatable_supported_permission, application:)

          user = create(
            :user,
            with_signin_permissions_for: [application],
            with_permissions: { application => [old_delegatable_permission.name, old_non_delegatable_permission.name] },
          )

          current_user = create(:user)
          current_user.stubs(:publishing_manager?).returns(true)
          sign_in current_user

          stub_policy(
            current_user,
            { application:, user: },
            policy_class: Users::ApplicationPolicy,
            edit_permissions?: true,
          )

          get :edit, params: { user_id: user, application_id: application }

          assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{old_delegatable_permission.id}']"
          assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_delegatable_permission.id}']"
          assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{old_non_delegatable_permission.id}']", count: 0
          assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_non_delegatable_permission.id}']", count: 0
        end
      end
    end
  end

  context "#update" do
    context "when a user can update another's permissions" do
      should "update non-signin permissions, retaining the signin permission, then redirect to the applications path" do
        application = create(:application)
        old_permission = create(:supported_permission, application:)
        new_permission = create(:supported_permission, application:)

        user = create(
          :user,
          with_signin_permissions_for: [application],
          with_permissions: { application => [old_permission.name] },
        )

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: true,
        )

        patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [new_permission.id] } }

        assert_redirected_to user_applications_path(user)
        assert_same_elements [new_permission, application.signin_permission], user.supported_permissions
      end

      should "assign the application id to the application_id flash" do
        application = create(:application)
        old_permission = create(:supported_permission, application:)
        new_permission = create(:supported_permission, application:)

        user = create(
          :user,
          with_signin_permissions_for: [application],
          with_permissions: { application => [old_permission.name] },
        )

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: true,
        )

        patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [new_permission.id] } }

        assert_equal application.id, flash[:application_id]
      end

      context "when current_permission_ids and new_permission_id are provided instead of supported_permission_ids" do
        setup do
          @application = create(:application)
          @old_permissions = create_list(:supported_permission, 2, application: @application)
          @new_permission = create(:supported_permission, application: @application)

          @user = create(
            :user,
            with_signin_permissions_for: [@application],
            with_permissions: { @application => @old_permissions.map(&:name) },
          )

          @current_user = create(:admin_user)
          sign_in @current_user

          stub_policy(
            @current_user,
            { application: @application, user: @user },
            policy_class: Users::ApplicationPolicy,
            edit_permissions?: true,
          )
        end

        should "use the relevant params to update permissions" do
          patch(
            :update,
            params: {
              user_id: @user,
              application_id: @application,
              application: {
                current_permission_ids: @old_permissions.map(&:id),
                new_permission_id: @new_permission.id,
              },
            },
          )

          assert_redirected_to user_applications_path(@user)

          assert_same_elements [*@old_permissions, @new_permission, @application.signin_permission], @user.supported_permissions
        end

        context "when the add_more param is 'true'" do
          should "update permissions then redirect back to the edit page" do
            patch(
              :update,
              params: {
                user_id: @user,
                application_id: @application,
                application: {
                  current_permission_ids: @old_permissions.map(&:id),
                  new_permission_id: @new_permission.id,
                  add_more: "true",
                },
              },
            )

            assert_redirected_to edit_user_application_permissions_path(@user, @application)

            assert_same_elements [*@old_permissions, @new_permission, @application.signin_permission], @user.supported_permissions
          end
        end
      end
    end

    context "when a user cannot update another's permissions" do
      should "prevent unauthenticated users" do
        application = create(:application)
        user = create(:user)

        patch :update, params: { user_id: user, application_id: application }

        assert_redirected_to "/users/sign_in"
      end

      should "prevent unauthorised users" do
        application = create(:application)
        user = create(:user, with_signin_permissions_for: [application])

        current_user = create(:admin_user)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: false,
        )

        patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [] } }

        assert_not_authorised
      end

      should "raise an exception if the user doesn't have access to the application" do
        sign_in create(:admin_user)

        application = create(:application)
        user = create(:user)

        assert_raises(ActiveRecord::RecordNotFound) do
          patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [] } }
        end
      end

      should "raise an exception if the application is retired" do
        sign_in create(:admin_user)

        application = create(:application, retired: true)
        user = create(:user, with_signin_permissions_for: [application])

        assert_raises(ActiveRecord::RecordNotFound) do
          patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [] } }
        end
      end

      should "raise an exception if the application is API-only" do
        sign_in create(:admin_user)

        application = create(:application, api_only: true)
        user = create(:user, with_signin_permissions_for: [application])

        assert_raises(ActiveRecord::RecordNotFound) do
          patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [] } }
        end
      end
    end

    should "when updating permissions for app A, prevent additionally adding or removing permissions for app B" do
      application_a = create(:application)
      application_a_old_permission = create(:supported_permission, application: application_a)
      application_a_new_permission = create(:supported_permission, application: application_a)

      application_b = create(:application)
      application_b_old_permission = create(:supported_permission, application: application_b)
      application_b_new_permission = create(:supported_permission, application: application_b)

      user = create(
        :user,
        with_signin_permissions_for: [application_a, application_b],
        with_permissions: {
          application_a => [application_a_old_permission.name],
          application_b => [application_b_old_permission.name],
        },
      )

      current_user = create(:admin_user)
      sign_in current_user

      [application_a, application_b].each do |application|
        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: true,
        )
      end

      patch(
        :update,
        params: {
          user_id: user,
          application_id: application_a,
          application: { supported_permission_ids: [application_a_new_permission.id, application_b_new_permission.id] },
        },
      )

      assert_same_elements [
        application_a_new_permission,
        application_b_old_permission,
        application_a.signin_permission,
        application_b.signin_permission,
      ], user.supported_permissions

      assert_not_includes user.supported_permissions, application_a_old_permission
      assert_not_includes user.supported_permissions, application_b_new_permission
    end

    should "prevent permissions that are not grantable from the UI being added or removed" do
      application = create(:application)
      old_grantable_permission = create(:supported_permission, application:)
      new_grantable_permission = create(:supported_permission, application:)
      old_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)
      new_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

      user = create(
        :user,
        with_signin_permissions_for: [application],
        with_permissions: { application => [old_grantable_permission.name, old_non_grantable_permission.name] },
      )

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
      )

      patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [new_grantable_permission.id, new_non_grantable_permission.id] } }

      assert_same_elements [
        old_non_grantable_permission,
        new_grantable_permission,
        application.signin_permission,
      ], user.supported_permissions
    end

    context "when the current user is a publishing manager with access to the app" do
      should "prevent adding or removing non-delegatable permissions" do
        application = create(:application)
        old_delegatable_permission = create(:delegatable_supported_permission, application:)
        new_delegatable_permission = create(:delegatable_supported_permission, application:)
        old_non_delegatable_permission = create(:non_delegatable_supported_permission, application:)
        new_non_delegatable_permission = create(:non_delegatable_supported_permission, application:)

        user = create(
          :user,
          with_signin_permissions_for: [application],
          with_permissions: { application => [old_delegatable_permission.name, old_non_delegatable_permission.name] },
        )

        current_user = create(:user, with_signin_permissions_for: [application])
        current_user.stubs(:publishing_manager?).returns(true)
        sign_in current_user

        stub_policy(
          current_user,
          { application:, user: },
          policy_class: Users::ApplicationPolicy,
          edit_permissions?: true,
        )

        patch(
          :update,
          params: {
            user_id: user,
            application_id: application,
            application: {
              supported_permission_ids: [new_delegatable_permission.id, new_non_delegatable_permission.id],
            },
          },
        )

        assert_same_elements [
          old_non_delegatable_permission,
          new_delegatable_permission,
          application.signin_permission,
        ], user.supported_permissions
      end
    end
  end
end
