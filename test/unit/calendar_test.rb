require 'test_helper'

class CalendarTest < ActiveSupport::TestCase
  
  context "Calendar importer" do
    should "load calendar item successfully" do
      Calendar.path_to_json = 'single_calendar.json'
      
      expected_outcome = { "england-and-wales" => { 
        :calendars => { 
          "2011" => Calendar.new(
            :year => '2011', 
            :division => 'england-and-wales', 
            :evemts => [
              Event.new(:title => "New Year's Day", :date => Date.parse('2nd Jan 2011'), :notes => "Substitute day")
            ]
          )
        } 
      } }            
      
      assert_kind_of Calendar, Calendar.all_grouped_by_division['england-and-wales'][:calendars]['2011']
      assert_equal Calendar.all_grouped_by_division['england-and-wales'][:calendars]['2011'].events.size, 1
      assert_kind_of Event, Calendar.all_grouped_by_division['england-and-wales'][:calendars]['2011'].events[0]
      assert_equal Calendar.all_grouped_by_division['england-and-wales'][:calendars]['2011'].events[0].title, "New Year's Day"
      
    end
  end
  
end
