class CalendarController < ApplicationController
  before_filter :find_scope
  before_filter :find_calendar, :only => :show

  def index
    expires_in 24.hours, :public => true unless Rails.env.development?
    if @scope
      repository = Calendar::Repository.new(@scope)
      @divisions = repository.all_grouped_by_division
      respond_to do |format|
        if params[:division]
          format.json { render :json => @divisions[params[:division]].to_json }
          format.ics  { render :text => Calendar.combine(@divisions, params[:division]).to_ics }
        else
          format.html { render "show_#{@scope_name}" }
          format.json { render :json => @divisions.to_json }
        end
      end
      set_slimmer_headers(
        format:      "calendar",
        proposition: "citizen",
        need_id:     repository.need_id,
        section:     repository.section
      )
    else
      render :file => "#{Rails.root}/public/404.html", :status => 404
    end
  end

  def show
    expires_in 24.hours, :public => true unless Rails.env.development?
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
      :bank_holidays => 'bank_holidays',
      :when_do_the_clocks_change => 'when_do_the_clocks_change'
    }
  end

  def find_scope
    @scope_name = normalize_scope(params[:scope]).to_sym
    @scope = scopes[@scope_name]
  rescue ArgumentError
    nil
  end

  def normalize_scope(scope)
    scope.gsub('-','_')
  end

  def find_calendar
    repository = Calendar::Repository.new(@scope)
    @calendar = repository.find_by_division_and_year(params[:division], params[:year])
  rescue ArgumentError
    nil
  end
end
