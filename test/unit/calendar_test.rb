require 'test_helper'

class CalendarTest < ActiveSupport::TestCase

  context "Calendar" do

    should "be able to access all calendars" do
      assert_equal Calendar.all_slugs.size, 3
      assert Calendar.all_slugs.include? '/bank-holidays'
      assert Calendar.all_slugs.include? '/combine-calendar'
      assert Calendar.all_slugs.include? '/single-calendar'
    end

    should "load calendar item successfully" do
      repository = Calendar::Repository.new("single-calendar")

      @calendar = repository.all_grouped_by_division['england-and-wales'][:calendars]['2011']

      assert_kind_of Calendar, @calendar
      assert_kind_of Event, @calendar.events[0]

      assert_equal @calendar.events.size, 1
      assert_equal @calendar.events[0].title, "New Year's Day"
      assert_equal @calendar.events[0].date, Date.parse('2nd January 2011')
      assert_equal @calendar.events[0].notes, "Substitute day"
    end

    should "throw exception when calendar does not exist" do
      assert_raises Calendar::CalendarNotFound do
        repository = Calendar::Repository.new("calendar-which-doesnt-exist")
      end
    end

    should "throw exception when calendar exists but division doesn't" do
      assert_raises Calendar::CalendarNotFound do
        repository = Calendar.combine("bank-holidays", "fake-division")
      end
    end

    should "expose calendar need_id and section" do
      repository = Calendar::Repository.new("single-calendar")
      assert_equal 42, repository.need_id
      assert_equal "Curmudgeonship", repository.section
    end

    should "load individual calendar given division and year" do
      repository = Calendar::Repository.new("bank-holidays")

      @calendar = repository.find_by_division_and_year( 'england-and-wales', '2011' )

      assert_kind_of Calendar, @calendar

      assert_equal @calendar.division, 'england-and-wales'
      assert_equal @calendar.year, '2011'
      assert_equal @calendar.events.size, 5

      assert_equal @calendar.events[2].title, "Royal wedding"
      assert_equal @calendar.events[2].date, Date.parse('29th April 2011')
      assert_equal @calendar.events[2].notes, ""
    end

    should "combine multiple calendars" do
      repository = Calendar::Repository.new("combine-calendar")

      @calendars = repository.all_grouped_by_division
      @combined = Calendar.combine(@calendars, 'united-kingdom')

      assert_equal @combined.events.size, 4
    end
  end

end
