require 'test_helper'

class SupportedPermissionsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, role: "superadmin")
    sign_in @user
  end

  context "GET index" do
    should "render the permissions list" do
      app = create(:application, name: "My first app", with_delegatable_supported_permissions: ["permission1"])

      get :index, doorkeeper_application_id: app.id

      assert_select "h1", /My first app/
      assert_select "td[class=name]", /permission1/
      assert_select "td[class=delegatable]", /Yes/
      assert_select "td[class=default]", /No/
      assert_select "a[id='add']", true
    end
  end

  context "GET new" do
    should "render the form" do
      app = create(:application, name: "My first app", with_supported_permissions: ["permission1"])
      get :new, doorkeeper_application_id: app.id
      assert_select "h1", /Add permission/
      assert_select ".breadcrumb li", /My first app/
      assert_select "input[name='supported_permission[name]']", true
      assert_select "input[name='supported_permission[delegatable]']", true
      assert_select "input[name='supported_permission[default]']", true
    end
  end

  context "POST create" do
    should "show error if name is not provided and not create a permission" do
      app = create(:application, name: "My first app")

      post :create, doorkeeper_application_id: app.id, supported_permission: { name: "" }

      assert_select "ul[class='errors'] li", "Name can't be blank"
      assert_equal app.reload.supported_permissions, [app.signin_permission]
    end

    should "create a new permission" do
      app = create(:application, name: "My first app")

      post :create, doorkeeper_application_id: app.id, supported_permission: { name: "permission1", default: '1' }

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
        created_at: 2.days.ago
      )

      put :update, doorkeeper_application_id: app.id, id: perm.id, supported_permission: { name: "", delegatable: '0', default: '0' }

      assert_select "ul[class='errors'] li", "Name can't be blank"
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
        created_at: 2.days.ago)

      put :update, doorkeeper_application_id: app.id, id: perm.id, supported_permission: { delegatable: '0', default: '0' }

      assert_redirected_to(controller: "supported_permissions", action: :index)
      assert_equal "Successfully updated permission permission1", flash[:notice]
      perm.reload
      refute perm.delegatable
      refute perm.default
    end
  end
end
