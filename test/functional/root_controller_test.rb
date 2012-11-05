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

  test "Your Applications should include apps you have permission to signin to" do
    exclusive_app = FactoryGirl.create(:application, name: "Exclusive app")
    everybody_app = FactoryGirl.create(:application, name: "Everybody app")
    user = FactoryGirl.create(:user)
    FactoryGirl.create(:permission, user: user, application: exclusive_app, permissions: [])
    FactoryGirl.create(:permission, user: user, application: everybody_app, permissions: ["signin"])
    
    sign_in user

    get :index
    
    assert_select "h3", "Everybody app"
    assert_select "h3", count: 1
  end

  # Because currently, permissions aren't required for the Support app
  test "Your Applications should include the 'Support' app if it exists, whether or not you have signin permission" do
    app = FactoryGirl.create(:application, name: "Support")
    user = FactoryGirl.create(:user)
    FactoryGirl.create(:permission, user: user, application: app, permissions: [])
    
    sign_in user

    get :index
    
    assert_select "h3", "Support"
  end
end
