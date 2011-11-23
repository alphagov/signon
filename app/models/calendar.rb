class Calendar

  attr_accessor :division, :year, :events

  @@path_to_json = 'bank_holidays.json'
  @@dir_to_json = (Rails.env.test?) ? "./test/fixtures/" : "./lib/data/"

  def initialize(attributes = nil)
    self.year     = attributes[:year]
    self.division = attributes[:division]
    self.events   = attributes[:events] || []
  end

  def self.path_to_json=(path)
    @@path_to_json = path
  end

  def self.all_grouped_by_division
    path = File.expand_path("#{@@dir_to_json}#{@@path_to_json}")
    data = JSON.parse(File.read(path)).symbolize_keys

    Hash[data[:divisions].map { |division, by_year|
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
      [division, calendars_for_division]
    }]
  end

  def self.find_by_division_and_year(division, year)
    self.all_grouped_by_division[division][:calendars][year]
  end

  def formatted_division
    case division
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
          event.summary         bh.title
          event.dtstart         bh.date
          event.dtend           bh.date
        end
      end
    end.export
  end

  def self.combine( calendars, division )
    combined_calendar = Calendar.new( :title => nil, :year => nil )

    calendars[division][:calendars].each do |year, cal|
      combined_calendar.events += cal.events
    end

    combined_calendar
  end

  def to_param
    "#{self.division}-#{self.year}"
  end

end
