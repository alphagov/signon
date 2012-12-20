require 'test_helper'

class Superuser::ApplicationsControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, role: "superuser")
    sign_in @user
  end

  context "GET index" do
    should "list applications" do
      FactoryGirl.create(:application, name: "My first app")
      get :index
      assert_select "td", /My first app/
    end
  end

  context "GET edit" do
    should "render the form" do
      app = FactoryGirl.create(:application, name: "My first app")
      get :edit, id: app.id
      assert_select "input[name='application[name]'][value='My first app']"
    end
  end

  context "PUT update" do
    should "update the application" do
      app = FactoryGirl.create(:application, name: "My first app")
      put :update, id: app.id, application: { name: "A better name" }
      
      assert_equal "A better name", app.reload.name
      assert_redirected_to superuser_applications_path
      assert_match(/updated/, flash[:notice])
    end

    should "redisplay the form if save fails" do
      app = FactoryGirl.create(:application, name: "My first app")
      put :update, id: app.id, application: { name: "" }
      assert_select "form#edit_application_#{app.id}"
    end
  end
end