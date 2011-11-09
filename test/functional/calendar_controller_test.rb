require 'test_helper'

class CalendarControllerTest < ActionController::TestCase
  
  context 'GET /bank-holidays/' do
    should "show a tab for each division" do
      get :index, :scope => "bank_holidays"             
      
      Calendar.all_grouped_by_division.each do |division, item|
        assert_select "#tabs li a.#{division}"
        assert_select "#guide-nav ##{division}"
      end                        
    end                                        
    
    should "show a table for each calendar with the correct caption" do
      get :index, :scope => "bank_holidays"
      
      Calendar.all_grouped_by_division.each do |division, item|
        assert_select "##{division} table", :count => item[:calendars].size
        
        item[:calendars].each do |year,cal|
          assert_select "##{division} table caption", "#{cal.year} Bank Holidays in #{cal.formatted_division}" 
        end
      end
    end                                                                    
        
    should "show a row for each bank holiday in the table" do
      get :index, :scope => "bank_holidays"
      
      Calendar.all_grouped_by_division.each do |division, item|
        
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
    
  end   
  
  context "GET /calendars/<calendar>.json" do
    should "contain calendar data" do
      get :show, :id => "england-and-wales-2011", :scope => "bank_holidays", :format => :json
                         
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
  end       
  
  context "GET /calendars/<calendar>.icl" do
     should "contain all calendar events" do
       get :show, :id => "england-and-wales-2011", :scope => "bank_holidays", :format => :ics
       
       output = "BEGIN:VCALENDAR\nPRODID;X-RICAL-TZSOURCE=TZINFO:-//com.denhaven2/NONSGML ri_cal gem//EN\nCALSCALE:GREGORIAN\nVERSION:2.0\n"
       
       Calendar.find_by_division_and_year('england-and-wales','2011').events.each do |event|
         output += "BEGIN:VEVENT\nDTEND;VALUE=DATE:#{event.date.strftime('%Y%m%d')}\nDTSTART;VALUE=DATE:#{event.date.strftime('%Y%m%d')}\nSUMMARY:#{event.title}\nEND:VEVENT\n"
       end
       
       output += "END:VCALENDAR\n"
       
       assert_equal output, @response.body
     end
  end
end
