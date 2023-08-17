require "test_helper"

class DoorkeeperIntegrationTest < ActionDispatch::IntegrationTest
  test "prevents access to Doorkeeper's /oauth/applications page" do
    visit "/oauth/applications"
  rescue ActionController::RoutingError => e
    assert_equal 'No route matches [GET] "/oauth/applications"', e.message
  end

  test "oauth2 authorization code grant type" do
    without_csrf_protection do
      app = create(:application)
      password = SecureRandom.urlsafe_base64
      user = create(:user, with_signin_permissions_for: [app], password:)

      sign_in user.email, password

      auth_code = request_authorization_code(app)

      reset!

      access_token = request_access_token(app, auth_code)

      user_data = request_user_data(app, access_token)
      assert_equal user.uid, user_data["user"]["uid"]
    end
  end

private

  def without_csrf_protection
    original_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original_value
  end

  def sign_in(email, password)
    post user_session_path, params: { user: { email:, password: } }
    assert_redirected_to root_path
  end

  def request_authorization_code(app)
    get oauth_authorization_path, params: { response_type: "code", client_id: app.uid, redirect_uri: app.redirect_uri }
    assert_response :redirect
    Rack::Utils.parse_query(URI.parse(response.location).query)["code"]
  end

  def request_access_token(app, auth_code)
    http_basic_auth = ActionController::HttpAuthentication::Basic.encode_credentials(app.uid, app.secret)
    post oauth_token_path, params: { grant_type: "authorization_code", code: auth_code, redirect_uri: app.redirect_uri },
                           headers: { Authorization: http_basic_auth }
    assert_response :success
    JSON.parse(response.body)["access_token"]
  end

  def request_user_data(app, access_token)
    get "/user.json", params: { client_id: app.uid }, headers: { Authorization: "Bearer #{access_token}" }
    assert_response :success
    JSON.parse(response.body)
  end
end
