class CalendarController < ApplicationController
  before_filter :find_scope
  before_filter :find_calendar, :only => :show

  def index
   if @scope
      @divisions = Calendar.all_grouped_by_division
      respond_to do |format|
        if params[:division]
          format.json { render :json => @divisions[params[:division]].to_json }
          format.ics  { render :text => Calendar.combine(@divisions, params[:division]).to_ics }
        else
          format.html { render "show_#{@scope_name}" }
          format.json { render :json => @divisions.to_json }
        end
      end
    else
      render :file => "#{Rails.root}/public/404.html", :status => 404
    end
  end

  def show
   if @scope and @calendar
    respond_to do |format|
      format.json { render :json => @calendar.to_json }
      format.ics { render :text => @calendar.to_ics }
    end
   else
     render :file => "#{Rails.root}/public/404.html", :status => 404
   end
  end

  private
    def scopes
      {
        :bank_holidays => 'bank_holidays.json',
        :when_do_the_clocks_change => 'daylight_saving.json'
      }
    end

    def find_scope
      @scope = nil
      @scope_name = normalize_scope(params[:scope]).to_sym

      if scopes.has_key?(@scope_name)
        @scope = scopes[@scope_name]
        Calendar.path_to_json = @scope
      end
    rescue ArgumentError
      nil
    end

    def normalize_scope(scope)
      scope.gsub('-','_')
    end

    def find_calendar
      @calendar = Calendar.find_by_division_and_year(params[:division], params[:year])
    rescue ArgumentError
      nil
    end


end
