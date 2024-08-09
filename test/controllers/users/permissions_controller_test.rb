require "test_helper"

class Users::PermissionsControllerTest < ActionController::TestCase
  context "#show" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      get :show, params: { user_id: user, application_id: application }

      assert_redirected_to "/users/sign_in"
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

    should "exclude applications that the user doesn't have access to" do
      sign_in create(:admin_user)

      application = create(:application)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application }
      end
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application }
      end
    end

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

    should "prevent unauthorised users" do
      application = create(:application)
      user = create(:user, with_signin_permissions_for: [application])

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: false

      get :show, params: { user_id: user, application_id: application }

      assert_not_authorised
    end
  end

  context "#edit" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      get :edit, params: { user_id: user, application_id: application }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorized users" do
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

    should "display checkboxes for the grantable permissions" do
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
    end

    should "include a hidden field for the signin permission so that it is not removed" do
      application = create(:application, with_non_delegatable_supported_permissions: ["perm-1", SupportedPermission::SIGNIN_NAME])
      user = create(
        :user,
        with_signin_permissions_for: [application],
        with_permissions: { application => %w[perm-1] },
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

      assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { user_id: user, application_id: application }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { user_id: user, application_id: application }
      end
    end

    should "raise an exception if the signin permission cannot be found" do
      application = create(:application)
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { user_id: user, application_id: application }
      end
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

  context "#update" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      patch :update, params: { user_id: user, application_id: application }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorized users" do
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

    should "redirect once the permissions have been updated" do
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
    end

    should "prevent permissions being added for apps that the current user does not have access to" do
      organisation = create(:organisation)

      application_1 = create(:application)
      application_2 = create(:application)
      application_2_permission = create(:delegatable_supported_permission, application: application_2)

      user = create(:user, organisation:, with_signin_permissions_for: [application_1])

      current_user = create(:organisation_admin_user, organisation:, with_signin_permissions_for: [application_1])
      sign_in current_user

      stub_policy(
        current_user,
        { application: application_1, user: },
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
      )

      patch :update, params: { user_id: user, application_id: application_1, application: { supported_permission_ids: [application_2_permission.id] } }

      user.reload

      assert_equal [application_1.signin_permission], user.supported_permissions
    end

    should "not remove the signin permission from the app when updating other permissions" do
      application = create(:application)
      new_permission = create(:supported_permission, application:)

      user = create(:user, with_signin_permissions_for: [application])

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
      )

      patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [new_permission.id] } }

      user.reload
      assert_same_elements [application.signin_permission, new_permission], user.supported_permissions
    end

    should "not remove permissions the user already has that are not grantable from ui" do
      application = create(:application)
      old_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)
      new_grantable_permission = create(:supported_permission, application:)

      user = create(
        :user,
        with_signin_permissions_for: [application],
        with_permissions: { application => [old_non_grantable_permission.name] },
      )

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
      )

      patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [new_grantable_permission.id] } }

      user.reload

      assert_same_elements [old_non_grantable_permission, new_grantable_permission, application.signin_permission], user.supported_permissions
    end

    should "prevent permissions being added for other apps" do
      updating_application = create(:application)
      other_application = create(:application)
      other_application_permission = create(:supported_permission, application: other_application)

      user = create(:user, with_signin_permissions_for: [updating_application])

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy(
        current_user,
        { application: updating_application, user: },
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
      )

      patch :update, params: { user_id: user, application_id: updating_application, application: { supported_permission_ids: [other_application_permission.id] } }

      user.reload

      assert_equal [updating_application.signin_permission], user.supported_permissions
    end

    should "prevent permissions being added that are not grantable from the ui" do
      application = create(:application)
      non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

      user = create(:user, with_signin_permissions_for: [application])

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy(
        current_user,
        { application:, user: },
        policy_class: Users::ApplicationPolicy,
        edit_permissions?: true,
      )

      patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: [non_grantable_permission.id] } }

      user.reload

      assert_equal [application.signin_permission], user.supported_permissions
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

    should "raise an exception if the user cannot be found" do
      application = create(:application)

      current_user = create(:admin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { user_id: "unknown-id", application_id: application, application: { supported_permission_ids: %w[id] } }
      end
    end

    should "raise an exception if the signin permission cannot be found" do
      application = create(:application)
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { user_id: user, application_id: application, application: { supported_permission_ids: %w[id] } }
      end
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

        @current_user.reload

        assert_equal [*@old_permissions, @new_permission, @application.signin_permission], @user.supported_permissions
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

          @current_user.reload

          assert_equal [*@old_permissions, @new_permission, @application.signin_permission], @user.supported_permissions
        end
      end
    end
  end
end
