require 'test_helper'

class CalendarControllerTest < ActionController::TestCase

  context 'GET /bank-holidays/' do
    should "show a tab for each division" do
      get :index, :scope => "bank-holidays"

      repository = Calendar::Repository.new("bank-holidays")
      repository.all_grouped_by_division.each do |division, item|
        assert_select "#tabs li a.#{division}"
        assert_select "#guide-nav ##{division}"
      end
    end

    should "show a table for each calendar with the correct caption" do
      get :index, :scope => "bank-holidays"

      repository = Calendar::Repository.new("bank-holidays")
      repository.all_grouped_by_division.each do |division, item|
        assert_select "##{division} table", :count => item[:calendars].size

        item[:calendars].each do |year,cal|
          assert_select "##{division} table caption", "#{cal.year} Bank Holidays in #{cal.formatted_division}"
        end
      end
    end

    should "show a row for each bank holiday in the table" do
      get :index, :scope => "bank-holidays"

      repository = Calendar::Repository.new("bank-holidays")
      repository.all_grouped_by_division.each do |division, item|

        item[:calendars].each do |year,cal|
          assert_select "##{division} table" do
            cal.events.each do |event|
              assert_select "tr" do
                assert_select "td.calendar_date", :text => event.date.strftime('%d %B')
                assert_select "td.calendar_day", :text => event.date.strftime('%A')
                assert_select "td.calendar_title", :text => event.title
                assert_select "td.calendar_notes", :text => event.notes
              end
            end
          end
        end
      end
    end

    should "send analytics headers" do
      get :index, scope: "bank-holidays"

      assert_equal "Life in the UK",  @response.headers["X-Slimmer-Section"]
      assert_equal "121",             @response.headers["X-Slimmer-Need-ID"].to_s
      assert_equal "calendar",        @response.headers["X-Slimmer-Format"]
      assert_equal "citizen",         @response.headers["X-Slimmer-Proposition"]
    end
  end

  context "GET /calendars/<calendar>.json" do
    should "contain calendar data with individual calendar" do
      get :show, :division => "england-and-wales", :year => "2011", :scope => "bank-holidays", :format => :json

      output = {
        "events" => [
          {"date"=>"2011-01-03", "notes"=>"Substitute day", "title"=>"New Year's Day"},
          {"date"=>"2011-04-22", "notes"=>"", "title"=>"Good Friday"},
          {"date"=>"2011-04-29", "notes"=>"", "title"=>"Royal wedding"},
          {"date"=>"2011-12-26", "notes"=>"Substitute day", "title"=>"Christmas Day"},
          {"date"=>"2011-12-27", "notes"=>"Substitute day", "title"=>"Boxing Day"}
        ],
        "division"=>"england-and-wales",
        "year"=>"2011"
      }

      assert_equal output, JSON.parse(@response.body)
    end

    should "contain calendar with division" do
      get :index, :division => "england-and-wales", :scope => "bank-holidays", :format => :json

      output = {
        "division" => "england-and-wales",
        "calendars" => {
          "2011" => {
            "year" => "2011",
            "division" => "england-and-wales",
            "events" => [
              {"date"=>"2011-01-03", "notes"=>"Substitute day", "title"=>"New Year's Day"},
              {"date"=>"2011-04-22", "notes"=>"", "title"=>"Good Friday"},
              {"date"=>"2011-04-29", "notes"=>"", "title"=>"Royal wedding"},
              {"date"=>"2011-12-26", "notes"=>"Substitute day", "title"=>"Christmas Day"},
              {"date"=>"2011-12-27", "notes"=>"Substitute day", "title"=>"Boxing Day"}
            ]
          },
          "2012" => {
            "year" => "2012",
            "division" => "england-and-wales",
            "events" => [
              {"date"=>"2012-01-02", "notes"=>"Substitute day", "title"=>"New Year's Day"},
              {"date"=>"2012-05-07", "notes"=>"", "title"=>"Early May Bank Holiday"},
              {"date"=>"2012-12-25", "notes"=>"", "title"=>"Christmas Day"},
              {"date"=>"2012-12-26", "notes"=>"", "title"=>"Boxing Day"}
            ]
          }
        }
      }

      assert_equal output, JSON.parse(@response.body)
    end
  end

  context "GET /calendars/<calendar>.icl" do
     should "contain all calendar events with an individual calendar" do
       get :show, :division => "england-and-wales", :year => "2011", :scope => "bank-holidays", :format => :ics

       output = "BEGIN:VCALENDAR\nPRODID;X-RICAL-TZSOURCE=TZINFO:-//com.denhaven2/NONSGML ri_cal gem//EN\nCALSCALE:GREGORIAN\nVERSION:2.0\n"

       repository = Calendar::Repository.new("bank-holidays")
       repository.find_by_division_and_year('england-and-wales','2011').events.each do |event|
         output += "BEGIN:VEVENT\nDTEND;VALUE=DATE:#{event.date.strftime('%Y%m%d')}\nDTSTART;VALUE=DATE:#{event.date.strftime('%Y%m%d')}\nSUMMARY:#{event.title}\nEND:VEVENT\n"
       end

       output += "END:VCALENDAR\n"

       assert_equal output, @response.body
     end

     should "contain all calendar events for combined calendars" do
        get :index, :division => "england-and-wales", :scope => "bank-holidays", :format => :ics

        output = "BEGIN:VCALENDAR\nPRODID;X-RICAL-TZSOURCE=TZINFO:-//com.denhaven2/NONSGML ri_cal gem//EN\nCALSCALE:GREGORIAN\nVERSION:2.0\n"

        repository = Calendar::Repository.new("bank-holidays")
        Calendar.combine(repository.all_grouped_by_division, 'england-and-wales').events.each do |event|
          output += "BEGIN:VEVENT\nDTEND;VALUE=DATE:#{event.date.strftime('%Y%m%d')}\nDTSTART;VALUE=DATE:#{event.date.strftime('%Y%m%d')}\nSUMMARY:#{event.title}\nEND:VEVENT\n"
        end

        output += "END:VCALENDAR\n"

        assert_equal output, @response.body
      end
  end
end
