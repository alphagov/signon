require "test_helper"

class Account::PermissionsControllerTest < ActionController::TestCase
  context "#show" do
    should "prevent unauthenticated users" do
      application = create(:application)

      get :show, params: { application_id: application }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude permissions that aren't grantable from the UI" do
      application = create(:application)
      grantable_permission = create(:supported_permission, application:)
      non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

      user = create(:admin_user, with_signin_permissions_for: [application])

      sign_in user

      get :show, params: { application_id: application }

      assert_select "td", text: grantable_permission.name
      assert_select "td", text: non_grantable_permission.name, count: 0
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { application_id: application }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { application_id: application }
      end
    end

    should "order permissions by whether the user has access and then alphabetically" do
      application = create(:application,
                           with_non_delegatable_supported_permissions: %w[uuu aaa ttt bbb])
      user = create(:admin_user,
                    with_signin_permissions_for: [application],
                    with_permissions: { application => %w[aaa ttt] })

      sign_in user

      get :show, params: { application_id: application }

      assert_equal %w[signin aaa ttt bbb uuu], assigns(:permissions).map(&:name)
    end
  end

  context "#edit" do
    should "prevent unauthenticated users" do
      application = create(:application)

      get :edit, params: { application_id: application }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { application_id: application }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { application_id: application }
      end
    end

    should "display checkboxes for the grantable permissions" do
      application = create(:application)
      old_grantable_permission = create(:supported_permission, application:)
      new_grantable_permission = create(:supported_permission, application:)
      new_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

      user = create(
        :admin_user,
        with_signin_permissions_for: [application],
        with_permissions: { application => [old_grantable_permission.name] },
      )

      sign_in user

      get :edit, params: { application_id: application }

      assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{old_grantable_permission.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_grantable_permission.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{new_non_grantable_permission.id}']", count: 0
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
    end

    should "include a hidden field for the signin permission so that it is not removed" do
      application = create(:application, with_non_delegatable_supported_permissions: %w[perm-1])

      user = create(
        :admin_user,
        with_signin_permissions_for: [application],
        with_permissions: { application => %w[perm-1] },
      )

      sign_in user

      get :edit, params: { application_id: application }

      assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
    end

    context "for apps with greater than eight supported permissions" do
      setup do
        @application = create(:application)
        @old_permissions = create_list(:supported_permission, 2, application: @application)
        @new_permissions = create_list(:supported_permission, 7, application: @application)

        user = create(
          :admin_user,
          with_signin_permissions_for: [@application],
          with_permissions: { @application => @old_permissions.map(&:name) },
        )

        sign_in user

        get :edit, params: { application_id: @application }
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

      patch :update, params: { application_id: application }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent permissions being added for apps that the current user does not have access to" do
      application_1 = create(:application)
      application_2 = create(:application)
      application_2_permission = create(:supported_permission, application: application_2)

      current_user = create(:organisation_admin_user, with_signin_permissions_for: [application_1])
      sign_in current_user

      stub_policy current_user, [:account, application_1], edit_permissions?: true

      patch :update, params: { application_id: application_1, application: { supported_permission_ids: [application_2_permission.id] } }

      current_user.reload

      assert_equal [application_1.signin_permission], current_user.supported_permissions
    end

    should "not remove the signin permission from the app when updating other permissions" do
      application = create(:application)
      new_permission = create(:supported_permission, application:)

      current_user = create(:admin_user, with_signin_permissions_for: [application])
      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      patch :update, params: { application_id: application, application: { supported_permission_ids: [new_permission.id] } }

      current_user.reload
      assert_same_elements [application.signin_permission, new_permission], current_user.supported_permissions
    end

    should "not remove permissions the user already has that are not grantable from ui" do
      application = create(:application)
      old_non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)
      new_grantable_permission = create(:supported_permission, application:)

      current_user = create(
        :admin_user,
        with_signin_permissions_for: [application],
        with_permissions: { application => [old_non_grantable_permission.name] },
      )

      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      patch :update, params: { application_id: application, application: { supported_permission_ids: [new_grantable_permission.id] } }

      current_user.reload

      assert_same_elements [old_non_grantable_permission, new_grantable_permission, application.signin_permission], current_user.supported_permissions
    end

    should "prevent permissions being added for other apps" do
      updating_application = create(:application)
      other_application = create(:application)
      other_application_permission = create(:supported_permission, application: other_application)

      current_user = create(:admin_user, with_signin_permissions_for: [updating_application])

      sign_in current_user

      stub_policy current_user, [:account, updating_application], edit_permissions?: true

      patch :update, params: { application_id: updating_application, application: { supported_permission_ids: [other_application_permission.id] } }

      current_user.reload

      assert_equal [updating_application.signin_permission], current_user.supported_permissions
    end

    should "prevent permissions being added that are not grantable from the ui" do
      application = create(:application)
      non_grantable_permission = create(:supported_permission, application:, grantable_from_ui: false)

      current_user = create(:admin_user, with_signin_permissions_for: [application])
      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      patch :update, params: { application_id: application, application: { supported_permission_ids: [non_grantable_permission.id] } }

      current_user.reload

      assert_equal [application.signin_permission], current_user.supported_permissions
    end

    should "assign the application id to the application_id flash" do
      application = create(:application)
      old_permission = create(:supported_permission, application:)
      new_permission = create(:supported_permission, application:)

      user = create(
        :admin_user,
        with_signin_permissions_for: [application],
        with_permissions: { application => [old_permission.name] },
      )
      sign_in user

      patch :update, params: { application_id: application, application: { supported_permission_ids: [new_permission.id] } }

      assert_equal application.id, flash[:application_id]
    end

    context "when current_permission_ids and new_permission_id are provided instead of supported_permission_ids" do
      setup do
        @application = create(:application)
        @old_permissions = create_list(:supported_permission, 2, application: @application)
        @new_permission = create(:supported_permission, application: @application)

        @current_user = create(
          :admin_user,
          with_signin_permissions_for: [@application],
          with_permissions: { @application => @old_permissions.map(&:name) },
        )

        sign_in @current_user

        stub_policy @current_user, [:account, @application], edit_permissions?: true
      end

      should "use the relevant params to update permissions" do
        patch :update, params: { application_id: @application, application: { current_permission_ids: [*@old_permissions], new_permission_id: @new_permission.id } }

        # assert redirected to apps page
        assert_redirected_to account_applications_path

        @current_user.reload

        assert_equal [*@old_permissions, @new_permission, @application.signin_permission], @current_user.supported_permissions
      end

      context "when the add_more param is 'true'" do
        should "update permissions then redirect back to the edit page" do
          patch :update, params: { application_id: @application, application: { current_permission_ids: [*@old_permissions], new_permission_id: @new_permission.id, add_more: "true" } }

          assert_redirected_to edit_account_application_permissions_path(@application)

          @current_user.reload

          assert_equal [*@old_permissions, @new_permission, @application.signin_permission], @current_user.supported_permissions
        end
      end
    end
  end
end
