require "test_helper"

class Users::PermissionsControllerTest < ActionController::TestCase
  context "#show" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      get :show, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "exclude permissions that aren't grantable from the UI" do
      application = create(:application,
                           with_supported_permissions: %w[perm-1],
                           with_supported_permissions_not_grantable_from_ui: %w[perm-2])
      user = create(:user, with_signin_permissions_for: [application])

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links current_user
      stub_policy current_user, user, edit?: true

      get :show, params: { user_id: user, application_id: application.id }

      assert_select "td", text: "perm-1"
      assert_select "td", text: "perm-2", count: 0
    end

    should "exclude applications that the user doesn't have access to" do
      sign_in create(:admin_user)

      application = create(:application)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :show, params: { user_id: user, application_id: application.id }
      end
    end

    should "order permissions by whether the user has access and then alphabetically" do
      application = create(:application,
                           with_supported_permissions: %w[aaa bbb ttt uuu])
      user = create(:user,
                    with_signin_permissions_for: [application],
                    with_permissions: { application => %w[aaa ttt] })

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy_for_navigation_links current_user
      stub_policy current_user, user, edit?: true

      get :show, params: { user_id: user, application_id: application.id }

      assert_equal %w[signin aaa ttt bbb uuu], assigns(:permissions).map(&:name)
    end

    should "prevent unauthorised users" do
      application = create(:application)
      user = create(:user)
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      stub_policy current_user, user, edit?: false

      get :show, params: { user_id: user, application_id: application.id }

      assert_not_authorised
    end
  end

  context "#edit" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      get :edit, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "prevent unauthorized users" do
      application = create(:application)
      user = create(:user)
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, edit?: false

      get :edit, params: { user_id: user, application_id: application.id }

      assert_not_authorised
    end

    should "display checkboxes for the grantable permissions" do
      application = create(:application)
      perm1 = create(:supported_permission, application:, name: "perm-1")
      perm2 = create(:supported_permission, application:, name: "perm-2")
      perm3 = create(:supported_permission, application:, name: "perm-3", grantable_from_ui: false)
      user = create(:user, with_permissions: { application => %w[perm-1] })
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, edit?: true

      get :edit, params: { user_id: user.id, application_id: application.id }

      assert_select "input[type='checkbox'][checked='checked'][name='application[supported_permission_ids][]'][value='#{perm1.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{perm2.id}']"
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{perm3.id}']", count: 0
      assert_select "input[type='checkbox'][name='application[supported_permission_ids][]'][value='#{application.signin_permission.id}']", count: 0
    end

    should "include a hidden field for the signin permission so that it is not removed" do
      application = create(:application, with_supported_permissions: ["perm-1", SupportedPermission::SIGNIN_NAME])
      user = create(:user, with_permissions: { application => %w[perm-1] })
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, edit?: true

      get :edit, params: { user_id: user.id, application_id: application.id }

      assert_select "input[type='hidden'][value='#{application.signin_permission.id}']"
    end

    should "exclude retired applications" do
      sign_in create(:admin_user)

      application = create(:application, retired: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { user_id: user, application_id: application.id }
      end
    end

    should "exclude API-only applications" do
      sign_in create(:admin_user)

      application = create(:application, api_only: true)
      user = create(:user)

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { user_id: user, application_id: application.id }
      end
    end

    should "raise an exception if the signin permission cannot be found" do
      application = create(:application)
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        get :edit, params: { user_id: user, application_id: application.id }
      end
    end
  end

  context "#update" do
    should "prevent unauthenticated users" do
      application = create(:application)
      user = create(:user)

      patch :update, params: { user_id: user, application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "redirect once the permissions have been updated" do
      application = create(:application, with_supported_permissions: %w[new old])
      user = create(:user, with_permissions: { application => %w[old] })
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: true

      new_permission = application.supported_permissions.find_by(name: "new")

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [new_permission.id] } }

      assert_redirected_to user_applications_path(user)
    end

    should "prevent permissions being added for apps that the current user does not have access to" do
      organisation = create(:organisation)

      application1 = create(:application)
      application2 = create(:application, with_supported_permissions: %w[app2-permission])

      user = create(:user, organisation:)
      user.grant_application_signin_permission(application1)

      current_user = create(:organisation_admin_user, organisation:)
      current_user.grant_application_signin_permission(application1)
      sign_in current_user

      permission = stub_user_application_permission(user, application1)
      stub_policy current_user, permission, update?: true

      app2_permission = application2.supported_permissions.find_by!(name: "app2-permission")

      patch :update, params: { user_id: user, application_id: application1, application: { supported_permission_ids: [app2_permission.id] } }

      user.reload

      assert_equal [application1.signin_permission], user.supported_permissions
    end

    should "not remove the signin permission from the app when updating other permissions" do
      application = create(:application, with_supported_permissions: %w[other])
      user = create(:user)
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: true

      other_permission = application.supported_permissions.find_by(name: "other")

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [other_permission.id] } }

      user.reload
      assert_same_elements [application.signin_permission, other_permission], user.supported_permissions
    end

    should "not remove permissions the user already has that are not grantable from ui" do
      application = create(:application, with_supported_permissions: %w[other], with_supported_permissions_not_grantable_from_ui: %w[not_from_ui])
      user = create(:user)
      user.grant_application_signin_permission(application)
      user.grant_application_permission(application, "not_from_ui")

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: true

      other_permission = application.supported_permissions.find_by(name: "other")
      not_from_ui_permission = application.supported_permissions.find_by(name: "not_from_ui")

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [other_permission.id] } }

      user.reload

      assert_same_elements [other_permission, application.signin_permission, not_from_ui_permission], user.supported_permissions
    end

    should "prevent permissions being added for other apps" do
      other_application = create(:application, with_supported_permissions: %w[other])
      application = create(:application)
      user = create(:user)
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: true

      other_permission = other_application.supported_permissions.find_by(name: "other")

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [other_permission.id] } }

      user.reload

      assert_equal [application.signin_permission], user.supported_permissions
    end

    should "prevent permissions being added that are not grantable from the ui" do
      application = create(:application, with_supported_permissions_not_grantable_from_ui: %w[not_from_ui])
      user = create(:user)
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: true

      not_from_ui_permission = application.supported_permissions.find_by(name: "not_from_ui")

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [not_from_ui_permission.id] } }

      user.reload

      assert_equal [application.signin_permission], user.supported_permissions
    end

    should "assign the application id to the application_id flash" do
      application = create(:application, with_supported_permissions: %w[new old])
      user = create(:user, with_permissions: { application => %w[old] })
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: true

      new_permission = application.supported_permissions.find_by(name: "new")

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [new_permission.id] } }

      assert_equal application.id, flash[:application_id]
    end

    should "raise an exception if the user cannot be found" do
      application = create(:application)

      current_user = create(:admin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { user_id: "unknown-id", application_id: application.id, application: { supported_permission_ids: %w[id] } }
      end
    end

    should "raise an exception if the signin permission cannot be found" do
      application = create(:application)
      user = create(:user)

      current_user = create(:admin_user)
      sign_in current_user

      assert_raises(ActiveRecord::RecordNotFound) do
        patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: %w[id] } }
      end
    end

    should "prevent unauthorised users" do
      application = create(:application)
      user = create(:user)
      user.grant_application_signin_permission(application)

      current_user = create(:admin_user)
      sign_in current_user

      permission = stub_user_application_permission(user, application)
      stub_policy current_user, permission, update?: false

      patch :update, params: { user_id: user, application_id: application.id, application: { supported_permission_ids: [] } }

      assert_not_authorised
    end
  end

private

  def stub_user_application_permission(user, application)
    permission = UserApplicationPermission.new
    UserApplicationPermission.stubs(:for).with(user, application).returns(permission)
    permission
  end
end
