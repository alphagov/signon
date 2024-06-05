require "test_helper"

class Account::PermissionsControllerTest < ActionController::TestCase
  context "#show" do
    should "prevent unauthenticated users" do
      application = create(:application)

      get :show, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude permissions that aren't grantable from the UI" do
      application = create(:application,
                           with_supported_permissions: %w[perm-1],
                           with_supported_permissions_not_grantable_from_ui: %w[perm-2])
      user = create(:admin_user, with_signin_permissions_for: [application])

      sign_in user

      get :show, params: { application_id: application.id }

      assert_select "td", text: "perm-1"
      assert_select "td", text: "perm-2", count: 0
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { application_id: application.id }
      end
    end

    should "order permissions by whether the user has access and then alphabetically" do
      application = create(:application,
                           with_supported_permissions: %w[aaa bbb ttt uuu])
      user = create(:admin_user,
                    with_signin_permissions_for: [application],
                    with_permissions: { application => %w[aaa ttt] })

      sign_in user

      get :show, params: { application_id: application.id }

      assert_equal %w[signin aaa ttt bbb uuu], assigns(:permissions).map(&:name)
    end
  end

  context "#edit" do
    should "prevent unauthenticated users" do
      application = create(:application)

      get :edit, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { application_id: application.id }
      end
    end

    should "display checkboxes for the grantable permissions" do
      application = create(:application)
      perm1 = create(:supported_permission, application:, name: "perm-1")
      perm2 = create(:supported_permission, application:, name: "perm-2")
      perm3 = create(:supported_permission, application:, name: "perm-3", grantable_from_ui: false)
      user = create(:admin_user, with_permissions: { application => ["perm-1", SupportedPermission::SIGNIN_NAME] })
      sign_in user

      get :edit, params: { application_id: application.id }

      assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{perm1.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{perm2.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{perm3.id}']", count: 0
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
    end

    should "include a hidden field for the signin permission so that it is not removed" do
      application = create(:application, with_supported_permissions: ["perm-1", SupportedPermission::SIGNIN_NAME])
      user = create(:admin_user, with_permissions: { application => ["perm-1", SupportedPermission::SIGNIN_NAME] })
      sign_in user

      get :edit, params: { application_id: application.id }

      assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
    end

    context "for apps with greater than eight supported permissions" do
      setup do
        @application = create(:application)
        @perm_granted_1 = create(:supported_permission, application: @application, name: "perm_granted_1")
        @perm_granted_2 = create(:supported_permission, application: @application, name: "perm_granted_2")
        @perm_ungranted_1 = create(:supported_permission, application: @application, name: "perm_ungranted_1")
        @perm_ungranted_2 = create(:supported_permission, application: @application, name: "perm_ungranted_2")
        @perm_ungranted_3 = create(:supported_permission, application: @application, name: "perm_ungranted_3")
        @perm_ungranted_4 = create(:supported_permission, application: @application, name: "perm_ungranted_4")
        @perm_ungranted_5 = create(:supported_permission, application: @application, name: "perm_ungranted_5")
        @perm_ungranted_6 = create(:supported_permission, application: @application, name: "perm_ungranted_6")
        @perm_ungranted_7 = create(:supported_permission, application: @application, name: "perm_ungranted_7")
        user = create(:admin_user, with_permissions: { @application => ["perm_granted_1", "perm_granted_2", SupportedPermission::SIGNIN_NAME] })

        sign_in user

        get :edit, params: { application_id: @application.id }
      end

      should "display a select component for grantable but non-existing permissions" do
        assert_select "select[name='application[new_permission_id]']"
      end

      should "include a hidden field representing whether the user wants to add more permissions, defaulting to false" do
        assert_select "input[type='hidden'][name='application[add_more]'][value='false']"
      end

      should "display checkboxes for the existing permissions" do
        assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{@perm_granted_1.id}']"
        assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{@perm_granted_2.id}']"
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_1.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_2.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_3.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_4.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_5.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_6.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@perm_ungranted_7.id}']", count: 0
        assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{@application.signin_permission.id}']", count: 0
      end
    end
  end

  context "#update" do
    should "prevent unauthenticated users" do
      application = create(:application)

      patch :update, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent permissions being added for apps that the current user does not have access to" do
      application1 = create(:application)
      application2 = create(:application, with_supported_permissions: %w[app2-permission])

      current_user = create(:organisation_admin_user)
      current_user.grant_application_signin_permission(application1)
      sign_in current_user

      stub_policy current_user, [:account, Doorkeeper::Application], index?: true
      stub_policy current_user, [:account, application1], edit_permissions?: true

      app2_permission = application2.supported_permissions.find_by!(name: "app2-permission")

      patch :update, params: { application_id: application1, application: { supported_permission_ids: [app2_permission.id] } }

      current_user.reload

      assert_equal [application1.signin_permission], current_user.supported_permissions
    end

    should "not remove the signin permission from the app when updating other permissions" do
      application = create(:application, with_supported_permissions: %w[other])

      current_user = create(:admin_user)
      current_user.grant_application_signin_permission(application)
      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      other_permission = application.supported_permissions.find_by(name: "other")

      patch :update, params: { application_id: application.id, application: { supported_permission_ids: [other_permission.id] } }

      current_user.reload
      assert_same_elements [application.signin_permission, other_permission], current_user.supported_permissions
    end

    should "not remove permissions the user already has that are not grantable from ui" do
      application = create(:application, with_supported_permissions: %w[other], with_supported_permissions_not_grantable_from_ui: %w[not_from_ui])

      current_user = create(:admin_user)
      current_user.grant_application_signin_permission(application)
      current_user.grant_application_permission(application, "not_from_ui")

      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      other_permission = application.supported_permissions.find_by(name: "other")
      not_from_ui_permission = application.supported_permissions.find_by(name: "not_from_ui")

      patch :update, params: { application_id: application.id, application: { supported_permission_ids: [other_permission.id] } }

      current_user.reload

      assert_same_elements [other_permission, application.signin_permission, not_from_ui_permission], current_user.supported_permissions
    end

    should "prevent permissions being added for other apps" do
      other_application = create(:application, with_supported_permissions: %w[other])
      application = create(:application)

      current_user = create(:admin_user)
      current_user.grant_application_signin_permission(application)

      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      other_permission = other_application.supported_permissions.find_by(name: "other")

      patch :update, params: { application_id: application.id, application: { supported_permission_ids: [other_permission.id] } }

      current_user.reload

      assert_equal [application.signin_permission], current_user.supported_permissions
    end

    should "prevent permissions being added that are not grantable from the ui" do
      application = create(:application, with_supported_permissions_not_grantable_from_ui: %w[not_from_ui])

      current_user = create(:admin_user)
      current_user.grant_application_signin_permission(application)
      sign_in current_user

      stub_policy current_user, [:account, application], edit_permissions?: true

      not_from_ui_permission = application.supported_permissions.find_by(name: "not_from_ui")

      patch :update, params: { application_id: application.id, application: { supported_permission_ids: [not_from_ui_permission.id] } }

      current_user.reload

      assert_equal [application.signin_permission], current_user.supported_permissions
    end

    should "assign the application id to the application_id flash" do
      application = create(:application, with_supported_permissions: %w[new])
      user = create(:admin_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
      sign_in user

      new_permission = application.supported_permissions.find_by(name: "new")

      patch :update, params: { application_id: application.id, application: { supported_permission_ids: [new_permission.id] } }

      assert_equal application.id, flash[:application_id]
    end

    context "when current_permission_ids and new_permission_id are provided instead of supported_permission_ids" do
      setup do
        @application = create(:application)
        @perm_granted_1 = create(:supported_permission, application: @application, name: "perm_granted_1")
        @perm_granted_2 = create(:supported_permission, application: @application, name: "perm_granted_2")
        @perm_ungranted = create(:supported_permission, application: @application, name: "perm_ungranted")

        @current_user = create(:admin_user, with_permissions: { @application => ["perm_granted_1", "perm_granted_2", SupportedPermission::SIGNIN_NAME] })

        sign_in @current_user

        stub_policy @current_user, [:account, @application], edit_permissions?: true
      end

      should "use the relevant params to update permissions" do
        patch :update, params: { application_id: @application.id, application: { current_permission_ids: [@perm_granted_1.id, @perm_granted_2.id], new_permission_id: @perm_ungranted.id } }

        # assert redirected to apps page
        assert_redirected_to account_applications_path

        @current_user.reload

        assert_equal [@perm_granted_1, @perm_granted_2, @perm_ungranted, @application.signin_permission], @current_user.supported_permissions
      end

      context "when the add_more param is 'true'" do
        should "update permissions then redirect back to the edit page" do
          patch :update, params: { application_id: @application.id, application: { current_permission_ids: [@perm_granted_1.id, @perm_granted_2.id], new_permission_id: @perm_ungranted.id, add_more: "true" } }

          assert_redirected_to edit_account_application_permissions_path(@application)

          @current_user.reload

          assert_equal [@perm_granted_1, @perm_granted_2, @perm_ungranted, @application.signin_permission], @current_user.supported_permissions
        end
      end
    end
  end
end
