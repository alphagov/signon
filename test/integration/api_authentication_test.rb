require 'test_helper'
require 'helpers/token_auth_support'
 
class ApiAuthenticationTest < ActionDispatch::IntegrationTest
  include TokenAuthSupport

  def access_user_endpoint(token = nil)
    get "/user.json", {}, token.nil? ? {} : {"HTTP_AUTHORIZATION" => "Bearer #{token}"}
  end

  setup do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])
    user = create(:user, with_permissions: { app => ["write"] })
    user.authorisations.create!(application_id: app.id)
  end

  should "grant access to the user details with a valid access token" do
    access_user_endpoint(get_valid_token.token)

    parsed_response = JSON.parse(response.body)
    assert parsed_response.has_key?('user')
    assert parsed_response['user']['permissions'].is_a?(Array)
  end

  should "not grant access without an access token" do
    access_user_endpoint

    assert_equal 401, response.status
  end

  should "not grant access with an invalid access token" do
    access_user_endpoint(get_valid_token.token.reverse)

    assert_equal 401, response.status
  end

  should "not grant access when access token has expired" do
    access_user_endpoint(get_expired_token.token)

    assert_equal 401, response.status
  end

  should "not grant access when access token has been revoked" do
    access_user_endpoint(get_revoked_token.token)

    assert_equal 401, response.status
  end
end
