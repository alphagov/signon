require 'test_helper'
require 'helpers/token_auth_support'
 
class ApiAuthenticationTest < ActionDispatch::IntegrationTest
  include TokenAuthSupport

  setup do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])
    user = create(:user, with_permissions: { app => ["write"] })
    user.authorisations.create!(application_id: app.id)
  end

  should "grant access to the user details with a valid access token" do
    set_bearer_token(get_valid_token.token)
    visit "/user.json"

    parsed_response = JSON.parse(page.source)
    assert parsed_response.has_key?('user')
    assert parsed_response['user']['permissions'].is_a?(Array)
  end

  should "not grant access without an access token" do
    visit "/user.json"

    assert_equal 401, page.status_code
  end

  should "not grant access with an invalid access token" do
    set_bearer_token(get_valid_token.token.reverse)
    visit "/user.json"

    assert_equal 401, page.status_code
  end

  should "not grant access when access token has expired" do
    set_bearer_token(get_expired_token.token)
    visit "/user.json"

    assert_equal 401, page.status_code
  end

  should "not grant access when access token has been revoked" do
    set_bearer_token(get_revoked_token.token)
    visit "/user.json"

    assert_equal 401, page.status_code
  end
end
