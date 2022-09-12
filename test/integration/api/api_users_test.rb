require "test_helper"

class ApiUsersTest < ActionDispatch::IntegrationTest
  name = "example-name"
  email = "example-name@example.org"
  endpoint = "/api/v1/api-users"
  create_params = { "name" => name, "email" => email }

  test "#show responds with a 401 error when an invalid token is given" do
    ENV["SIGNON_ADMIN_PASSWORD"] = SecureRandom.uuid
    get endpoint, headers: { "HTTP_AUTHORIZATION" => "Bearer invalid-token" }
    assert_unauthorized(response)
  end

  test "#show responds with a 401 error when SIGNON_ADMIN_PASSWORD env var is unset" do
    ENV["SIGNON_ADMIN_PASSWORD"] = nil
    get endpoint
    assert_unauthorized(response)
  end

  test "#show responds with a 400 when required params are missing" do
    get_req(endpoint, params: {})
    assert_equal JSON.generate({ error: "param is missing or the value is empty: email" }), response.body
    assert_equal 400, response.status
  end

  test "#show responds with a 404 when the api user doesn't exist" do
    create(:api_user, name: name, email: email)
    get_req(endpoint, params: { email: "invalid@example.org" })
    assert_equal JSON.generate({ error: "Record not found" }), response.body
    assert_equal 404, response.status
  end

  test "#show returns the api_user" do
    create(:api_user, name: "Alternate 1", email: "alt-1@example.org")
    create(:api_user, name: name, email: email)
    create(:api_user, name: "Alternate 2", email: "alt-2@example.org")
    get_req(endpoint, params: { email: email })

    user = JSON.parse(response.body).fetch("api_user")
    assert_equal String, user.fetch("id").class
    assert_equal [], user.fetch("tokens")
    assert_equal 200, response.status
  end

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
    post_req(endpoint, params: create_params.except("name", "email"))
    assert_equal JSON.generate({ error: "param is missing or the value is empty: name and email" }), response.body
    assert_equal 400, response.status
  end

  test "#create provided email is invalid" do
    post_req(endpoint, params: { "name" => name, "email" => "an invalid email address" })
    assert_equal JSON.generate({ error: "Validation failed: Email is invalid" }), response.body
    assert_equal 400, response.status
  end

  test "#create when api_user email is already taken" do
    create(:api_user, email: email, name: name)
    post_req(endpoint, params: create_params)
    assert_equal JSON.generate({ error: "Record not unique" }), response.body
    assert_equal 409, response.status
  end

  test "#create adds an api user" do
    post_req(endpoint, params: create_params)
    assert_equal 200, response.status
    user = JSON.parse(response.body).fetch("api_user")
    assert_equal String, user.fetch("id").class
    assert_equal [], user.fetch("tokens")
  end

  #
  # Helpers
  #

  def assert_unauthorized(response)
    assert_equal "HTTP Token: Access denied.\n", response.body
    assert_equal 401, response.status
  end

  def get_req(endpoint, params: {})
    get endpoint, params: params, headers: headers
  end

  def post_req(endpoint, params: {})
    post endpoint, params: params.to_json, headers: headers
  end

  def headers
    token = SecureRandom.uuid
    ENV["SIGNON_ADMIN_PASSWORD"] = token
    { "HTTP_AUTHORIZATION" => "Bearer #{token}", "CONTENT_TYPE" => "application/json" }
  end
end
