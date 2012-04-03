require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "changing passwords to something strong should succeed" do
    user, orig_password = change_user_password(:user, 'a new strong p4ssw0rd')

    assert_equal "302", response.code
    assert_equal root_url, response.location

    user.reload
    assert_not_equal orig_password, user.encrypted_password
  end

  test "changing password to something too short should fail" do
    user, orig_password = change_user_password(:user, 'short')

    assert_equal "200", response.code
    assert_match "too short", response.body

    user.reload
    assert_equal orig_password, user.encrypted_password
  end

  test "changing password to something too weak should fail" do
    user, orig_password = change_user_password(:user, 'zymophosphate')

    assert_equal "200", response.code
    assert_match "not strong enough", response.body

    user.reload
    assert_equal orig_password, user.encrypted_password
  end

  private

  def change_user_password(user_factory, new_password)
    user = FactoryGirl.create(user_factory)
    orig_password = user.encrypted_password
    sign_in user
    
    post :update, { user: { password: new_password, password_confirmation: new_password } }
    
    return user, orig_password
  end
end
