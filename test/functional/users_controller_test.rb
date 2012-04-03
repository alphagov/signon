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

  test "fetching json profile with a valid oauth token should succeed" do
    user = FactoryGirl.create(:user)
    application = FactoryGirl.create(:application)
    token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

    @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
    get :show, {:format => :json}

    assert_equal "200", response.code
    assert_equal user.to_sensible_json, response.body
  end

  test "fetching json profile with an invalid oauth token should not succeed" do
    user = FactoryGirl.create(:user)
    application = FactoryGirl.create(:application)
    token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

    @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
    get :show, {:format => :json}

    assert_equal "401", response.code
  end

  test "fetching json profile without any bearer header should not succeed" do
    get :show, {:format => :json}
    assert_equal "401", response.code
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
