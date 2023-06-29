require "test_helper"

class DoorkeeperIntegrationTest < ActionDispatch::IntegrationTest
  test "prevents access to Doorkeeper's /oauth/applications page" do
    visit "/oauth/applications"

    assert_equal 403, page.status_code
  end
end
