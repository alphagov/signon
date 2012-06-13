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
      assert_redirected_to admin_users_path
    end

    should "let you set the is_admin flag" do
      not_an_admin = FactoryGirl.create(:user)
      put :update, id: not_an_admin.id, user: { is_admin: true }
      assert_equal true, not_an_admin.reload.is_admin
    end

    should "redisplay the form if save fails" do
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { name: "" }
      assert_select "form.edit_user"
    end
  end

  should "disallow access to non-admins" do
    @user.update_attribute(:is_admin, false)
    get :index
    assert_redirected_to root_path
  end
end
