require "test_helper"

class AuthorisationsTest < ActionDispatch::IntegrationTest
  setup do
    @api_user = create(:api_user)
    @application = create(:application)
  end

  create_endpoint = "/api/v1/authorisations"
  test_endpoint = "/api/v1/authorisations/test"
  endpoints_with_params = [create_endpoint, test_endpoint].zip([
    %w[application_name api_user_email],
    %w[application_name api_user_email token],
  ])

  endpoints_with_params.each do |endpoint, _required_params|
    test "endpoint #{endpoint} responds with a 401 error when an invalid token is given" do
      ENV["SIGNON_ADMIN_PASSWORD"] = SecureRandom.uuid
      post endpoint, headers: { "HTTP_AUTHORIZATION" => "Bearer invalid-token" }
      assert_unauthorized(response)
    end

    test "endpoint #{endpoint} responds with a 401 error when SIGNON_ADMIN_PASSWORD env var is unset" do
      ENV["SIGNON_ADMIN_PASSWORD"] = nil
      post endpoint
      assert_unauthorized(response)
    end
  end

  endpoints_with_params.each do |endpoint, required_params|
    test "endpoint #{endpoint} responds with a 400 when required params are missing" do
      request(endpoint)
      assert_equal 400, response.status
      assert_equal JSON.generate({ error: "param is missing or the value is empty: #{required_params.to_sentence}" }), response.body
    end
  end

  test "#create provided api_user_email is invalid" do
    request(create_endpoint, params: {
      api_user_email: "invalid@example.org",
      application_name: @application.name,
    })
    assert_equal 404, response.status
    assert_equal JSON.generate({ error: "Not found" }), response.body
  end

  test "#create provided application_name is invalid" do
    request(create_endpoint, params: {
      api_user_email: @api_user.email,
      application_name: "Invalid name",
    })
    assert_equal JSON.generate({ error: "Not found" }), response.body
    assert_equal 404, response.status
  end

  test "#create adds an application auth token to an api_user" do
    request(create_endpoint, params: {
      api_user_email: @api_user.email,
      application_name: @application.name,
    })
    assert_equal 200, response.status
    body = JSON.parse(response.body)
    assert_equal @application.name, body.fetch("application_name")
    assert_equal body.fetch("token").length, 43
    assert_match(/[A-Za-z0-9]\w+/, body.fetch("token"))
  end

  test "#test confirms that a token has been created" do
    request(create_endpoint, params: {
      api_user_email: @api_user.email,
      application_name: @application.name,
    })
    assert_equal 200, response.status
    token = JSON.parse(response.body).fetch("token")
    request(test_endpoint, params: {
      api_user_email: @api_user.email,
      application_name: @application.name,
      token: token,
    })
    assert_equal 200, response.status
    assert_equal JSON.generate(application_name: @application.name), response.body
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
