require 'test_helper'

class RootControllerTest < ActionController::TestCase
  test "visiting root#index should require authentication" do
    get :index
    assert_equal "302", response.code
    assert_equal new_user_session_url, response.location
  end

  test "visiting root#index as a signed-in user should succeed" do
    sign_in FactoryGirl.create(:user)
    get :index
    assert_equal "200", response.code
  end

  test "sets the X-Frame-Options header to SAMEORIGIN" do
    sign_in FactoryGirl.create(:user)
    get :index
    assert_equal "SAMEORIGIN", response.header['X-Frame-Options']
  end
end
