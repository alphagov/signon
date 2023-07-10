require "test_helper"

class DoorkeeperIntegrationTest < ActionDispatch::IntegrationTest
  test "prevents access to Doorkeeper's /oauth/applications page" do
    visit "/oauth/applications"
  rescue ActionController::RoutingError => e
    assert_equal 'No route matches [GET] "/oauth/applications"', e.message
  end
end
