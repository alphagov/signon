class Calendar

  REPOSITORY_PATH = Rails.env.test? ? "test/fixtures" : "lib/data"

  class CalendarNotFound < Exception
  end

  def self.all_slugs
    slugs = []
    Dir.glob("#{REPOSITORY_PATH}/*.json").each do |path|
      slugs << path.gsub(REPOSITORY_PATH, '').gsub('.json','')
    end
    slugs
  end

  class Repository
    def initialize(name)
      @json_path = Rails.root.join(Calendar::REPOSITORY_PATH, name + ".json")

      unless File.exists? @json_path
        raise Calendar::CalendarNotFound.new( @json_path )
      end
    end

    def need_id
      parsed_data[:need_id]
    end

    def section
      parsed_data[:section]
    end

    def parsed_data
      @parsed_data ||= JSON.parse(File.read(@json_path)).symbolize_keys
    rescue
      false
    end

    def all_grouped_by_division
      Hash[parsed_data[:divisions].map { |division, by_year|
        calendars_for_division = {
          division:  division,
          calendars: Hash[by_year.sort.map { |year, events|
            calendar = Calendar.new(year: year, division: division, events:
              events.map { |event|
                Event.new(
                  title: event['title'],
                  date:  Date.strptime(event['date'], "%d/%m/%Y"),
                  notes: event['notes']
                )
              }
            )
            [calendar.year, calendar]
          }]
        }
        calendars_for_division[:whole_calendar] = Calendar.combine_inside_division calendars_for_division[:calendars]
        [division, calendars_for_division]
      }]
    end

    def find_by_division_and_year(division, year)
      all_grouped_by_division[division][:calendars][year]
    end
  end

  attr_accessor :division, :year, :events

  def initialize(attributes = nil)
    self.year     = attributes[:year]
    self.division = attributes[:division]
    self.events   = attributes[:events] || []
  end

  def upcoming_event
    @events.select{|e| e.date > Date.today-1.day }.first
  end

  def event_today?
    upcoming_event.date == Date.today
  end

  def formatted_division(str = division)
    case str
    when 'england-and-wales'
      "England and Wales"
    when 'scotland'
      "Scotland"
    when 'ni'
      "Northern Ireland"
    end
  end

  def to_ics
    RiCal.Calendar do |cal|
      self.events.each do |bh|
        cal.event do |event|
          event.summary bh.title
          event.dtstart bh.date
          event.dtend   bh.date
        end
      end
    end.export
  end

  def self.combine(calendars, division)
    raise CalendarNotFound unless calendars[division]
    self.combine_inside_division calendars[division][:calendars]
  end

  def self.combine_inside_division(calendars)
    combined_calendar = Calendar.new(:title => nil, :year => nil)
    calendars.each do |year, cal|
      combined_calendar.events += cal.events
    end
    combined_calendar
  end  

  def to_param
    "#{self.division}-#{self.year}"
  end
end
