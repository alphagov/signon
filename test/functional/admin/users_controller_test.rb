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
      assert_select "td.email", /#{@user.email}/
    end
  end

  should "disallow access to non-admins" do
    @user.update_attribute(:is_admin, false)
    get :index
    assert_redirected_to root_path
  end
end
