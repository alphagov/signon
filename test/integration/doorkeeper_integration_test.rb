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

  test "oauth2 authorization code grant type with pkce extension" do
    without_csrf_protection do
      app = create(:application)
      password = SecureRandom.urlsafe_base64
      user = create(:user, with_signin_permissions_for: [app], password:)

      sign_in user.email, password

      pkce = PKCE.new

      auth_code = request_authorization_code(app, code_challenge_method: pkce.code_challenge_method, code_challenge: pkce.code_challenge)

      reset!

      access_token = request_access_token(app, auth_code, code_verifier: pkce.code_verifier)

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

  def request_authorization_code(app, code_challenge_method: nil, code_challenge: nil)
    get oauth_authorization_path, params: { response_type: "code", client_id: app.uid, redirect_uri: app.redirect_uri, code_challenge_method:, code_challenge: }
    assert_response :redirect
    Rack::Utils.parse_query(URI.parse(response.location).query)["code"]
  end

  def request_access_token(app, auth_code, code_verifier: nil)
    http_basic_auth = ActionController::HttpAuthentication::Basic.encode_credentials(app.uid, app.secret)
    post oauth_token_path, params: { grant_type: "authorization_code", code: auth_code, redirect_uri: app.redirect_uri, code_verifier: },
                           headers: { Authorization: http_basic_auth }
    assert_response :success
    JSON.parse(response.body)["access_token"]
  end

  def request_user_data(app, access_token)
    get "/user.json", params: { client_id: app.uid }, headers: { Authorization: "Bearer #{access_token}" }
    assert_response :success
    JSON.parse(response.body)
  end

  class PKCE
    attr_reader :code_verifier, :code_challenge_method, :code_challenge

    def initialize
      # From https://github.com/omniauth/omniauth-oauth2/blob/3e7ee11c84153e6f0c19d38a5e63cda550f6925c/lib/omniauth/strategies/oauth2.rb#L108
      @code_verifier = SecureRandom.hex(64)

      # From https://github.com/omniauth/omniauth-oauth2/blob/3e7ee11c84153e6f0c19d38a5e63cda550f6925c/lib/omniauth/strategies/oauth2.rb#L41
      @code_challenge_method = "S256"

      # From https://github.com/omniauth/omniauth-oauth2/blob/3e7ee11c84153e6f0c19d38a5e63cda550f6925c/lib/omniauth/strategies/oauth2.rb#L35-L40
      @code_challenge = Base64.urlsafe_encode64(Digest::SHA2.digest(@code_verifier), padding: false)
    end
  end
end
