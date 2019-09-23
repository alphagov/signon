require "test_helper"

class DoorkeeperApplicationsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, role: "superadmin")
    sign_in @user
  end

  context "GET index" do
    should "list applications" do
      create(:application, name: "My first app")
      get :index
      assert_select "td", /My first app/
    end
  end

  context "GET edit" do
    should "render the form" do
      app = create(:application, name: "My first app")
      get :edit, params: { id: app.id }
      assert_select "input[name='doorkeeper_application[name]'][value='My first app']"
    end
  end

  context "PUT update" do
    should "update the application" do
      app = create(:application, name: "My first app")
      put :update, params: { id: app.id, doorkeeper_application: { name: "A better name" } }

      assert_equal "A better name", app.reload.name
      assert_redirected_to doorkeeper_applications_path
      assert_match(/updated/, flash[:notice])
    end

    should "redisplay the form if save fails" do
      app = create(:application, name: "My first app")
      put :update, params: { id: app.id, doorkeeper_application: { name: "" } }
      assert_select "form#edit_doorkeeper_application_#{app.id}"
    end
  end
end
