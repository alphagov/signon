require "test_helper"

class ApplicationsTest < ActionDispatch::IntegrationTest
  name = "Cat herder"
  home_uri = "https://cats.example.org"
  redirect_uri = "https://cats.example.org/redirect"
  description = "Herds cats"
  permissions = %w[cat_herder herder_of_cats]
  endpoint = "/api/v1/applications"
  create_params = {
    "name" => name,
    "home_uri" => home_uri,
    "redirect_uri" => redirect_uri,
    "description" => description,
    "permissions" => permissions,
  }

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
    assert_equal 400, response.status
    assert_equal JSON.generate({ error: "param is missing or the value is empty: name" }), response.body
  end

  test "#show responds with a 404 when the application doesn't exist" do
    create(:application, name: name, supports_push_updates: true)
    get_req(endpoint, params: { "name" => "doesnt exist" })
    assert_equal 404, response.status
    assert_equal JSON.generate({ error: "Record not found" }), response.body
  end

  test "#show returns an application" do
    create(:application, name: name, supports_push_updates: true, with_supported_permissions: %w[perm1])
    get_req(endpoint, params: { "name" => name })
    assert_equal 200, response.status
    assert_success_body(response)
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
    post_req(endpoint, params: create_params.except("home_uri", "description"))
    assert_equal 400, response.status
    assert_equal JSON.generate({ error: "param is missing or the value is empty: description and home_uri" }), response.body
  end

  test "#create provided redirect_uri is invalid" do
    post_req(endpoint, params: create_params.merge("redirect_uri" => "a bad redirect_uri!!!!!"))
    assert_equal 400, response.status
    assert_equal JSON.generate({ error: "Validation failed: Redirect URI must be an absolute URI." }), response.body
  end

  test "#create when application already exists" do
    create(:application, name: name)
    post_req(endpoint, params: create_params.merge("name" => name))
    assert_equal 409, response.status
    assert_equal JSON.generate({ error: "Record not unique" }), response.body
  end

  test "#create adds an application" do
    post_req(endpoint, params: create_params)
    assert_equal 200, response.status
    assert_success_body(response)
  end

  test "#create with no permissions is successful" do
    post_req(endpoint, params: create_params.merge("permissions" => []))
    assert_equal 200, response.status
    assert_success_body(response)
  end

  test "#update responds with a 401 error when an invalid token is given" do
    ENV["SIGNON_ADMIN_PASSWORD"] = SecureRandom.uuid
    application = create(:application, name: name)
    patch "#{endpoint}/#{application.id}", headers: { "HTTP_AUTHORIZATION" => "Bearer invalid-token" }
    assert_unauthorized(response)
  end

  test "#update responds with a 401 error when SIGNON_ADMIN_PASSWORD env var is unset" do
    ENV["SIGNON_ADMIN_PASSWORD"] = nil
    application = create(:application, name: name)
    patch "#{endpoint}/#{application.id}"
    assert_unauthorized(response)
  end

  test "#update when app doesnt exist" do
    patch "#{endpoint}/12345678", headers: headers
    assert_equal 404, response.status
  end

  test "#update with no params" do
    application = create(:application, name: name)
    patch "#{endpoint}/#{application.id}", params: {}.to_json, headers: headers
    assert_equal 200, response.status
    assert_success_body(response)
  end

  test "#update with modifying application fields" do
    desired_name = "My new named app"
    application = create(:application)
    patch "#{endpoint}/#{application.id}", params: {
      name: desired_name,
    }.to_json, headers: headers
    assert_equal 200, response.status
    assert_success_body(response)
    data = JSON.parse(response.body).fetch("application")
    application.reload
    assert_equal desired_name, data.fetch("name")
    assert_equal desired_name, application.name
  end

  test "#update with adding permissions" do
    desired_permissions = %w[1 2 3]
    application = create(:application, name: name, with_supported_permissions: %w[1 2])
    patch "#{endpoint}/#{application.id}", params: {
      permissions: desired_permissions,
    }.to_json, headers: headers
    assert_equal 200, response.status
    assert_success_body(response)
    application.reload
    assert_equal desired_permissions, application.supported_permission_strings - Api::V1::ApplicationsController::DEFAULT_PERMISSIONS
  end

  test "#update with deleting permissions" do
    desired_permissions = %w[1]
    application = create(:application, name: name, with_supported_permissions: %w[1 2])
    patch "#{endpoint}/#{application.id}", params: {
      permissions: desired_permissions,
    }.to_json, headers: headers
    assert_equal 200, response.status
    assert_success_body(response)
    application.reload
    assert_equal desired_permissions, application.supported_permission_strings - Api::V1::ApplicationsController::DEFAULT_PERMISSIONS
  end

  test "#update with ignored params" do
    desired_redirect_uri = "https://malicious.example.org"
    application = create(:application, name: name, with_supported_permissions: %w[1 2])
    patch "#{endpoint}/#{application.id}", params: {
      redirect_uri: desired_redirect_uri,
    }.to_json, headers: headers
    assert_equal 200, response.status
    assert_success_body(response)
    application.reload
    assert_not_equal desired_redirect_uri, application.redirect_uri
  end

  #
  # Helpers
  #

  def assert_success_body(response)
    body = JSON.parse(response.body)
    app = body.fetch("application")
    assert_equal String, app.fetch("id").class
    assert_match(/^[A-Za-z0-9_-]{43}$/, app.fetch("oauth_id"))
    assert_match(/^[A-Za-z0-9_-]{43}$/, app.fetch("oauth_secret"))
  end

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
