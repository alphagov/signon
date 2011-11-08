class CalendarController < ApplicationController
  before_filter :find_calendar, :only => :show

  def index
    @divisions = Calendar.all.group_by(&:division)
  end
  
  def show
   if @calendar
    respond_to do |format|
      format.json { render :json => @calendar.to_json } 
      format.ics { render :text => @calendar.to_ics }
    end
   else
     render :file => "#{Rails.root}/public/404.html", :status => 404
   end
  end                         
  
  private
  def find_calendar
    @matches = params[:id].match(/^([A-Za-z-]+)\-([0-9]{4})/) 
    division = @matches[1] rescue nil
    year = @matches[2] rescue nil
    
    @calendar = Calendar.find_by_division_and_year(division, year) 
  rescue ArgumentError
    nil
  end
end
