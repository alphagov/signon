require 'test_helper'
require 'helpers/token_auth_support'

class ApiAuthenticationTest < ActionDispatch::IntegrationTest
  include TokenAuthSupport

  def access_user_endpoint(token = nil, params = {})
    headers = token.nil? ? {} : { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
    get "/user.json", params: params, headers: headers
  end

  setup do
    @app1 = create(:application, name: "MyApp", with_supported_permissions: ["write"])
    @user = create(:user, with_permissions: { @app1 => %w(signin write) })
    @user.authorisations.create!(application_id: @app1.id)
  end

  should "grant access to the user details with a valid access token" do
    access_user_endpoint(get_valid_token.token, client_id: @app1.uid)

    parsed_response = JSON.parse(response.body)
    assert parsed_response.has_key?('user')
    assert parsed_response['user']['permissions'].is_a?(Array)
  end

  should "grant access to the user details with a valid token, and no client_id specified" do
    # To maintain backwards compatibilty.  A client_id will be made mandatory
    # once all the clients have been upgraded to the new gds-sso

    access_user_endpoint(get_valid_token.token)

    parsed_response = JSON.parse(response.body)
    assert parsed_response.has_key?('user')
    assert parsed_response['user']['permissions'].is_a?(Array)
  end

  should "not grant access without 'signin' permission to the app" do
    @user.application_permissions.where(supported_permission_id: @app1.signin_permission).destroy_all
    access_user_endpoint(get_valid_token.token)

    assert_equal 401, response.status
  end

  should "not grant access without an access token" do
    access_user_endpoint nil, client_id: @app1.uid

    assert_equal 401, response.status
  end

  should "not grant access with an invalid access token" do
    access_user_endpoint(get_valid_token.token.reverse, client_id: @app1.uid)

    assert_equal 401, response.status
  end

  should "not grant access when access token has expired" do
    access_user_endpoint(get_expired_token.token, client_id: @app1.uid)

    assert_equal 401, response.status
  end

  should "not grant access when access token has been revoked" do
    access_user_endpoint(get_revoked_token.token, client_id: @app1.uid)

    assert_equal 401, response.status
  end

  should "not grant access when access token does not match client_id" do
    app2 = create(:application, name: "Another app")
    access_user_endpoint(get_valid_token.token, client_id: app2.uid)

    assert_equal 401, response.status
  end
end
