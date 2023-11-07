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
      application = create(:application,
                           with_supported_permissions: ["perm-1", "perm-2", SupportedPermission::SIGNIN_NAME],
                           with_supported_permissions_not_grantable_from_ui: %w[perm-3])
      user = create(:admin_user, with_permissions: { application => ["perm-1", SupportedPermission::SIGNIN_NAME] })
      sign_in user

      get :edit, params: { application_id: application.id }

      assert_select "input[type='checkbox'][checked='checked'][name='application[permissions][]'][value='perm-1']"
      assert_select "input[type='checkbox'][name='application[permissions][]'][value='perm-2']"
      assert_select "input[type='checkbox'][name='application[permissions][]'][value='perm-3']", count: 0
      assert_select "input[type='checkbox'][name='application[permissions][]'][value='signin']", count: 0
    end

    should "include a hidden field for the signin permission so that it is not removed" do
      application = create(:application, with_supported_permissions: ["perm-1", SupportedPermission::SIGNIN_NAME])
      user = create(:admin_user, with_permissions: { application => ["perm-1", SupportedPermission::SIGNIN_NAME] })
      sign_in user

      get :edit, params: { application_id: application.id }

      assert_select "input[type='hidden'][value='signin']"
    end
  end

  context "#update" do
    should "prevent unauthenticated users" do
      application = create(:application)

      patch :update, params: { application_id: application.id }

      assert_redirected_to "/users/sign_in"
    end

    should "replace the users permissions with new ones" do
      application = create(:application, with_supported_permissions: %w[new old])
      user = create(:admin_user, with_permissions: { application => ["old", SupportedPermission::SIGNIN_NAME] })
      sign_in user

      patch :update, params: { application_id: application.id, application: { permissions: %w[new] } }

      assert_equal %w[new], user.permissions_for(application)
      assert_redirected_to account_applications_path
    end

    should "assign the application id to the success flash" do
      application = create(:application, with_supported_permissions: %w[new])
      user = create(:admin_user, with_permissions: { application => [SupportedPermission::SIGNIN_NAME] })
      sign_in user

      patch :update, params: { application_id: application.id, application: { permissions: %w[new] } }

      assert_equal application.id, flash[:success]
    end
  end
end
