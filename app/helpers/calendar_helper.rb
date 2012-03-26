module CalendarHelper
  def next_clock_change
    @next_clock_change ||= @divisions['united-kingdom'][:whole_calendar].upcoming_event
  end

  def next_clock_change_description
    next_clock_change.notes.gsub(' one hour', '').downcase
  end

  def next_clock_change_date
    @divisions['united-kingdom'][:whole_calendar].upcoming_event.date.strftime('%d %B')
  end
end
