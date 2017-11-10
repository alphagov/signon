require 'test_helper'

class RootControllerTest < ActionController::TestCase
  def setup
    create(:application, name: 'Support')
  end

  test "visiting root#index should require authentication" do
    get :index
    assert_equal "302", response.code
    assert_equal new_user_session_url, response.location
  end

  test "visiting root#index as a signed-in user should succeed" do
    sign_in create(:user)
    get :index
    assert_equal "200", response.code
  end

  test "sets the X-Frame-Options header to SAMEORIGIN" do
    sign_in create(:user)
    get :index
    assert_equal "SAMEORIGIN", response.header['X-Frame-Options']
  end

  test "Your Applications should include apps you have permission to signin to" do
    exclusive_app = create(:application, name: "Exclusive app")
    everybody_app = create(:application, name: "Everybody app")
    user = create(:user, with_permissions: { exclusive_app => [], everybody_app => ["signin"] })

    sign_in user

    get :index

    assert_select "h3", "Everybody app"
    assert_select "h3", count: 1
  end
end
