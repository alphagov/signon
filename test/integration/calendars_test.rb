require 'integration_test_helper'

class CalendarsTest < ActionDispatch::IntegrationTest
  
  should "give a 404 status when a calendar does not exist" do
    visit '/maternity'
    assert page.status_code == 404
  end

end