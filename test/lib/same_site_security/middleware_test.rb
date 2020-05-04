require "test_helper"

class SameSiteSecurityMiddlewareTest < ActiveSupport::TestCase
  setup do
    headers = { "Content-Type" => "text/plain", "Set-Cookie" => "_signonotron2_session=abcd" }
    @app = proc { [200, headers, %w[OK]] }
  end

  context "when called with a GET request" do
    should "set cookies attributes properly" do
      middleware = SameSiteSecurity::Middleware.new(@app)
      Rack::MockRequest.new(middleware)
      env = Rack::MockRequest.env_for("/a-protected-url")
      _status, headers = middleware.call(env)

      cookies = headers["Set-Cookie"]
      assert_match "_signonotron2_session=abcd", cookies
      assert_match "SameSite=Lax", cookies
    end
  end
end
