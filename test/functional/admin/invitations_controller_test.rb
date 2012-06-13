require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, is_admin: true)
    sign_in @user
  end

  should "disallow access to non-admins" do
    @user.update_attribute(:is_admin, false)
    get :new
    assert_redirected_to root_path
  end
end
