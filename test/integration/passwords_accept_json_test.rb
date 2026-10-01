require "test_helper"

class PasswordsAcceptJsonTest < ActionDispatch::IntegrationTest
  setup do
    @show_exceptions = Rails.application.env_config["action_dispatch.show_exceptions"]
    Rails.application.env_config["action_dispatch.show_exceptions"] = :all
  end

  teardown { Rails.application.env_config["action_dispatch.show_exceptions"] = @show_exceptions }

  test "HEAD requests accepting json result in HTTP 406" do
    head "/users/password/edit", params: { reset_password_token: "invalid" },
                                 headers: { "Accept" => "application/json" }

    assert_response :not_acceptable
  end
end
