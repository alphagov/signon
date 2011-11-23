require 'test_helper'

class CalendarTest < ActiveSupport::TestCase

  context "Calendar" do
    should "load calendar item successfully" do
      Calendar.path_to_json = 'single_calendar.json'

      @calendar = Calendar.all_grouped_by_division['england-and-wales'][:calendars]['2011']

      assert_kind_of Calendar, @calendar
      assert_kind_of Event, @calendar.events[0]

      assert_equal @calendar.events.size, 1
      assert_equal @calendar.events[0].title, "New Year's Day"
      assert_equal @calendar.events[0].date, Date.parse('2nd January 2011')
      assert_equal @calendar.events[0].notes, "Substitute day"
    end

    should "load individual calendar given division and year" do
      Calendar.path_to_json = 'bank_holidays.json'

      @calendar = Calendar.find_by_division_and_year( 'england-and-wales', '2011' )

      assert_kind_of Calendar, @calendar

      assert_equal @calendar.division, 'england-and-wales'
      assert_equal @calendar.year, '2011'
      assert_equal @calendar.events.size, 5

      assert_equal @calendar.events[2].title, "Royal wedding"
      assert_equal @calendar.events[2].date, Date.parse('29th April 2011')
      assert_equal @calendar.events[2].notes, ""
    end

    should "combine multiple calendars" do
      Calendar.path_to_json = 'combine_calendar.json'

      @calendars = Calendar.all_grouped_by_division
      @combined = Calendar.combine(@calendars, 'united-kingdom')

      assert_equal @combined.events.size, 4
    end
  end

end
