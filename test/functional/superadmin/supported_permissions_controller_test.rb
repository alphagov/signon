require 'test_helper'

class Superadmin::SupportedPermissionsControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, role: "superadmin")
    sign_in @user
  end

  context "GET index" do
    should "render the form" do
      app = FactoryGirl.create(:application, name: "My first app")
      perm = FactoryGirl.create(:supported_permission, application_id: app.id, name: "permission1")
      get :index, application_id: app.id
      assert_select "h1", /My first app/
      assert_select "p[id='permissions']", /permission1/
      assert_select "a[id='add']", true
      assert_select "a[id='cancel']", true
    end
  end

  context "GET new" do
    should "render the form" do
      app = FactoryGirl.create(:application, name: "My first app")
      perm = FactoryGirl.create(:supported_permission, application_id: app.id, name: "permission1")
      get :new, application_id: app.id
      assert_select "h1", /My first app/
      assert_select "input[name='post[permission]']", true
    end
  end

  context "POST create" do
    should "create a new permission" do
      app = FactoryGirl.create(:application, name: "My first app")
      post :create, application_id: app.id, post:{ permission: "permission1" }
      assert_redirected_to(:controller => "supported_permissions", :action => :index)
      app.reload
      assert_equal app.supported_permissions.first.name, "permission1"
     end
  end

end