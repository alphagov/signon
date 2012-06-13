require 'test_helper'

class Admin::InvitationsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryGirl.create(:user, is_admin: true)
    sign_in @user
  end

  should "disallow access to non-admins" do
    @user.update_attribute(:is_admin, false)
    get :new
    assert_redirected_to root_path
  end
end
