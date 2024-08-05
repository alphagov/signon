require "test_helper"

class SupportedPermissionsControllerTest < ActionController::TestCase
  setup do
    @user = create(:superadmin_user)
    sign_in @user
  end

  context "GET index" do
    should "render the permissions list" do
      app = create(:application, name: "My first app", with_delegatable_supported_permissions: %w[permission1])

      get :index, params: { doorkeeper_application_id: app.id }

      assert_select "h1", /My first app/
      assert_select "tr:nth-child(2)" do |tr|
        assert_select tr, "td", /permission1/
        assert_select tr, "td", /Yes/
        assert_select tr, "td", /No/
      end
      assert_select "a", "Add permission"
    end
  end

  context "GET new" do
    should "render the form" do
      app = create(:application, name: "My first app", with_non_delegatable_supported_permissions: %w[permission1])
      get :new, params: { doorkeeper_application_id: app.id }
      assert_select "h1", /Add permission/
      assert_select ".govuk-breadcrumbs li", /My first app/
      assert_select "input[name='supported_permission[name]']", true
      assert_select "input[name='supported_permission[delegatable]']", true
      assert_select "input[name='supported_permission[default]']", true
    end
  end

  context "POST create" do
    should "show error if name is not provided and not create a permission" do
      app = create(:application, name: "My first app")

      post :create, params: { doorkeeper_application_id: app.id, supported_permission: { name: "" } }

      assert_select ".govuk-error-summary ul li", "Name can't be blank"
      assert_equal app.reload.supported_permissions, [app.signin_permission]
    end

    should "create a new permission" do
      app = create(:application, name: "My first app")

      post :create, params: { doorkeeper_application_id: app.id, supported_permission: { name: "permission1", default: "1" } }

      assert_redirected_to(controller: "supported_permissions", action: :index)
      assert_equal "Successfully added permission permission1 to My first app", flash[:notice]
      new_permission = app.reload.supported_permissions.first
      assert_equal new_permission.name, "permission1"
      assert new_permission.default
    end
  end

  context "PUT update" do
    should "show error if name is not provided and not edit the permission" do
      app = create(:application, name: "My first app")
      perm = create(
        :supported_permission,
        application_id: app.id,
        name: "permission1",
        delegatable: true,
        default: true,
        created_at: 2.days.ago,
      )

      put :update, params: { doorkeeper_application_id: app.id, id: perm.id, supported_permission: { name: "", delegatable: "0", default: "0" } }

      assert_select ".govuk-error-summary ul li", "Name can't be blank"
      perm.reload
      assert perm.delegatable
      assert perm.default
    end

    should "edit permission" do
      app = create(:application, name: "My first app")
      perm = create(
        :supported_permission,
        application_id: app.id,
        name: "permission1",
        delegatable: true,
        default: true,
        created_at: 2.days.ago,
      )

      put :update, params: { doorkeeper_application_id: app.id, id: perm.id, supported_permission: { delegatable: "0", default: "0" } }

      assert_redirected_to(controller: "supported_permissions", action: :index)
      assert_equal "Successfully updated permission permission1", flash[:notice]
      perm.reload
      assert_not perm.delegatable
      assert_not perm.default
    end
  end

  context "GET confirm_destroy" do
    should "render the permission and application names" do
      application = create(:application, name: "My first app", with_non_delegatable_supported_permissions: %w[permission1])

      get :confirm_destroy, params: { doorkeeper_application_id: application.id, id: application.supported_permissions.first.id }

      assert_select "p.govuk-body", "Are you sure you want to delete the \"permission1\" permission for \"My first app\"?"
    end
  end

  context "DELETE destroy" do
    should "delete the permission" do
      application = create(:application)
      supported_permission = create(:supported_permission, application:)

      delete :destroy, params: { doorkeeper_application_id: application.id, id: supported_permission.id }

      assert_redirected_to(controller: "supported_permissions", action: :index)
      assert_equal "Successfully deleted permission #{supported_permission.name}", flash[:notice]
      assert_not application.supported_permissions.include?(supported_permission)
    end
  end
end
