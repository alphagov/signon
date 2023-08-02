require "test_helper"

class Doorkeeper::TokensControllerTest < ActionController::TestCase
  should "handle OAuth v1 requests to create a token" do
    assert_recognizes({ controller: "doorkeeper/tokens", action: "create" }, { path: "oauth/access_token", method: :post })
  end

  should "handle OAuth v2 requests to create a token" do
    assert_recognizes({ controller: "doorkeeper/tokens", action: "create" }, { path: "oauth/token", method: :post })
  end
end
