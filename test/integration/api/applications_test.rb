require "test_helper"

class ApplicationsTest < ActionDispatch::IntegrationTest
  name = "Cat herder"
  home_uri = "https://cats.example.org"
  redirect_uri = "https://cats.example.org/redirect"
  description = "Herds cats"
  permissions = %w[cat_herder herder_of_cats]
  endpoint = "/api/v1/applications"
  params = {
    "name" => name,
    "home_uri" => home_uri,
    "redirect_uri" => redirect_uri,
    "description" => description,
    "permissions" => permissions,
  }

  test "#create responds with a 401 error when an invalid token is given" do
    ENV["SIGNON_ADMIN_PASSWORD"] = SecureRandom.uuid
    post endpoint, headers: { "HTTP_AUTHORIZATION" => "Bearer invalid-token" }
    assert_unauthorized(response)
  end

  test "#create responds with a 401 error when SIGNON_ADMIN_PASSWORD env var is unset" do
    ENV["SIGNON_ADMIN_PASSWORD"] = nil
    post endpoint
    assert_unauthorized(response)
  end

  test "#create responds with a 400 when required params are missing" do
    request(endpoint, params: params.except("home_uri", "description"))
    assert_equal 400, response.status
    assert_equal JSON.generate({ error: "param is missing or the value is empty: description and home_uri" }), response.body
  end

  test "#create provided redirect_uri is invalid" do
    request(endpoint, params: params.merge("redirect_uri" => "a bad redirect_uri!!!!!"))
    assert_equal 400, response.status
    assert_equal JSON.generate({ error: "Not valid" }), response.body
  end

  test "#create when application already exists" do
    create(:application, name: name)
    request(endpoint, params: params.merge("name" => name))
    assert_equal 400, response.status
    assert_equal JSON.generate({ error: "Record already exists" }), response.body
  end

  test "#create adds an application" do
    request(endpoint, params: params)
    assert_equal 200, response.status
    body = JSON.parse(response.body)
    assert_equal 43, body.fetch("oauth_id").length
    assert_match(/[A-Za-z0-9]\w+/, body.fetch("oauth_id"))
    assert_equal 43, body.fetch("oauth_secret").length
    assert_match(/[A-Za-z0-9]\w+/, body.fetch("oauth_secret"))
  end

  #
  # Helpers
  #

  def assert_unauthorized(response)
    assert_equal "HTTP Token: Access denied.\n", response.body
    assert_equal 401, response.status
  end

  def request(endpoint, params: {})
    token = SecureRandom.uuid
    ENV["SIGNON_ADMIN_PASSWORD"] = token
    auth_header = { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
    post endpoint, params: params, headers: auth_header
  end
end
