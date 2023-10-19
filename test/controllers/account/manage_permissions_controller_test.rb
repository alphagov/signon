require "test_helper"

class Account::ManagePermissionsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "GET show" do
    context "as Admin" do
      should "can give permissions to all applications" do
        user = create(:admin_user, email: "admin@gov.uk")
        sign_in user

        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        user.grant_application_signin_permission(delegatable_app)
        user.grant_application_signin_permission(non_delegatable_app)

        get :show

        assert_select ".container" do
          # can give permissions to a delegatable app
          assert_select "td", count: 1, text: delegatable_app.name
          # can give permissions to a non delegatable app
          assert_select "td", count: 1, text: non_delegatable_app.name
          # can give permissions to a delegatable app the admin doesn't have access to
          assert_select "td", count: 1, text: delegatable_no_access_to_app.name
          # can give permissions to a non-delegatable app the admin doesn't have access to
          assert_select "td", count: 1, text: non_delegatable_no_access_to_app.name
        end
      end

      should "not list retired applications" do
        user = create(:admin_user, email: "admin@gov.uk")
        sign_in user

        retired_app = create(:application, retired: true)
        user.grant_application_signin_permission(retired_app)

        get :show

        assert_select ".container" do
          assert_select "td", count: 0, text: retired_app.name
        end
      end

      should "not list API-only applications" do
        user = create(:admin_user, email: "admin@gov.uk")
        sign_in user

        api_only_app = create(:application, api_only: true)
        user.grant_application_signin_permission(api_only_app)

        get :show

        assert_select ".container" do
          assert_select "td", count: 0, text: api_only_app.name
        end
      end
    end

    context "organisation admin" do
      should "be able to give permissions only to applications they have access to and that also have delegatable signin permissions" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        organisation_admin = create(:organisation_admin_user, with_signin_permissions_for: [delegatable_app, non_delegatable_app])

        sign_in organisation_admin

        get :show

        assert_select "#editable-permissions" do
          # can give access to a delegatable app they have access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can not give access to a non-delegatable app they have access to
          assert_select "td", count: 0, text: non_delegatable_app.name
        end
      end

      should "be able to see all permissions including those they can't change" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Editor"])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Admin"])

        organisation_admin = create(
          :organisation_admin_user,
          with_permissions: {
            delegatable_app => %w[Editor],
            non_delegatable_app => [SupportedPermission::SIGNIN_NAME, "GDS Admin"],
          },
        )

        sign_in organisation_admin

        get :show

        assert_select "h2", "All permissions"
        assert_select "#all-permissions" do
          # can see permissions for a delegatable app that they have access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can see permissions to a non-delegatable app that they have access to
          assert_select "td", count: 1, text: non_delegatable_app.name
          # can see role
          assert_select "td", count: 1, text: "Editor"
          assert_select "td", count: 1, text: "GDS Admin"
        end
      end
    end

    context "super organisation admin" do
      should "be able to give permissions only to applications they have access to and that also have delegatable signin permissions" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        super_org_admin = create(:super_organisation_admin_user, with_signin_permissions_for: [delegatable_app, non_delegatable_app])

        sign_in super_org_admin

        get :show

        assert_select "#editable-permissions" do
          # can give access to a delegatable app they have access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can not give access to a non-delegatable app they have access to
          assert_select "td", count: 0, text: non_delegatable_app.name
        end
      end

      should "be able to see all permissions including those they can't change" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Editor"])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Admin"])

        super_org_admin = create(
          :super_organisation_admin_user,
          with_permissions: {
            delegatable_app => %w[Editor],
            non_delegatable_app => [SupportedPermission::SIGNIN_NAME, "GDS Admin"],
          },
        )

        sign_in super_org_admin

        get :show

        assert_select "h2", "All permissions"
        assert_select "#all-permissions" do
          # can see permissions for a delegatable app that they have access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can see permissions to a non-delegatable app that they have access to
          assert_select "td", count: 1, text: non_delegatable_app.name
          # can see role
          assert_select "td", count: 1, text: "Editor"
          assert_select "td", count: 1, text: "GDS Admin"
        end
      end
    end

    context "superadmin" do
      should "not be able to see all permissions to applications that they can't change" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Editor"])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Admin"])

        superadmin = create(:superadmin_user, with_signin_permissions_for: [delegatable_app, non_delegatable_app])

        sign_in superadmin

        get :show

        assert_select "h2", count: 0, text: "All permissions"
        assert_select "#all-permissions", count: 0
      end
    end
  end

  context "PUT update" do
    context "update application access" do
      setup do
        @user = create(:admin_user)
        sign_in @user
        @application = create(:application)
      end

      should "remove all applications access" do
        @user.grant_application_signin_permission(@application)

        put :update, params: { user: {} }

        assert_empty @user.reload.application_permissions
      end

      should "add application access" do
        put(
          :update,
          params: {
            user: {
              supported_permission_ids: [
                @application.supported_permissions.first.id,
              ],
            },
          },
        )

        assert_equal 1, @user.reload.application_permissions.count
      end

      should "redirect to Account page on success" do
        @user.grant_application_signin_permission(@application)

        put :update, params: { user: {} }

        assert_redirected_to account_path
        assert_match(/Your permissions have been updated./, flash[:notice])
      end
    end
  end
end
