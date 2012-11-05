require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, is_admin: true)
    sign_in @user
  end

  context "GET index" do
    should "list users" do
      FactoryGirl.create(:user, email: "another_user@email.com")
      get :index
      assert_select "td.email", /another_user@email.com/
    end

    should "let you paginate by the first letter of the name" do
      FactoryGirl.create(:user, name: "alf", email: "a@email.com")
      FactoryGirl.create(:user, name: "zed", email: "z@email.com")
      get :index, letter: "Z"
      assert_select "td.email", /z@email.com/
      assert_select "tbody tr", count: 1
    end

    context "filter" do
      should "filter results to users where their name or email contains the string" do
        FactoryGirl.create(:user, email: "a@another.gov.uk")
        FactoryGirl.create(:user, email: "a@dfid.gov.uk")
        get :index, filter: "dfid"
        assert_select "td.email", /a@dfid.gov.uk/
        assert_select "tbody tr", count: 1
      end
    end
  end

  context "GET edit" do
    should "show the form" do
      not_an_admin = FactoryGirl.create(:user)
      get :edit, id: not_an_admin.id
      assert_select "input[name='user[email]'][value='#{not_an_admin.email}']"
    end
  end

  context "PUT update" do
    should "update the user" do
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { email: "new@email.com" }

      assert_equal "new@email.com", another_user.reload.email
      assert_equal 200, response.status
      assert_equal "Updated user new@email.com successfully", flash[:notice]
    end

    should "let you set the is_admin flag" do
      not_an_admin = FactoryGirl.create(:user)
      put :update, id: not_an_admin.id, user: { is_admin: true }
      assert_equal true, not_an_admin.reload.is_admin
    end

    should "redisplay the form if save fails" do
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { name: "" }
      assert_select "form#edit_user_#{another_user.id}"
    end

    should "push changes to permissions out to apps (but only those ever used by them)" do
      another_user = FactoryGirl.create(:user)
      app = FactoryGirl.create(:application)
      unused_app = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, application: app, user: another_user)
      permission_for_unused_app = FactoryGirl.create(:permission, application: unused_app, user: another_user)
      # simulate them having used (and 'authorized' the app)
      ::Doorkeeper::AccessToken.create(resource_owner_id: another_user.id, application_id: app.id, token: "1234")

      PermissionUpdater.expects(:new).with(another_user, [app]).returns(mock("mock propagator", attempt: {}))

      permissions_attributes = { 
        permissions_attributes: { 
          0 => { 
            application_id: "#{app.id}",
            id: "#{permission.id}",
            signin_permission: "1",
            permissions: ["banana"]
          } 
        } 
      }      
      put :update, { id: another_user.id, user: { email: "new@email.com" } }.merge(permissions_attributes)

      assert_equal "new@email.com", another_user.reload.email
      assert_equal 200, response.status
    end
  end

  should "disallow access to non-admins" do
    @user.update_column(:is_admin, false)
    get :index
    assert_redirected_to root_path
  end
end
