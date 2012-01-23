require 'integration_test_helper'

class CalendarsTest < ActionDispatch::IntegrationTest

  should "give a 404 status when a calendar does not exist" do
    visit '/maternity'
    assert page.status_code == 404
  end

  should "give a 404 when asked for a division that doesn't exist" do
    visit "/when-do-the-clocks-change/A188770693.ics"
    assert page.status_code == 404
  end
end