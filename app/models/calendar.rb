class Calendar    
  
  attr_accessor :division, :year, :events
         
  @@path_to_json = 'bank_holidays.json'
  @@dir_to_json = (Rails.env.test?) ? "./test/fixtures/" : "./lib/data/"
  
  def initialize( attributes )
    self.year = attributes[:year]
    self.division = attributes[:division]
    self.events = attributes[:events] || []
  end                   
  
  def self.path_to_json=(path)
    @@path_to_json = path
  end
  
  def self.all_grouped_by_division
    calendars = []
                                  
    data = JSON.parse( File.read( File.expand_path( "#{@@dir_to_json}#{@@path_to_json}" ) ) ).symbolize_keys
    divisions = {}
  
    data[:divisions].each do |division|
      division_calendars = {}
    
      division[1].each do |calendars|
        calendars.to_a.each do |cal|     
          calendar = Calendar.new( :year => cal[0], :division => division[0] )                
          cal[1].each do |event|        
            calendar.events << Event.new( 
              :title => event['title'], 
              :date => Date.strptime(event['date'], "%d/%m/%Y"),                                                
              :notes => event['notes']
            )                     
          end                   
          division_calendars[calendar.year] = calendar                                                
        end                                                  
      end  
    
      divisions[division[0]] = { :division => division[0], :calendars => division_calendars }
    end
    
    divisions
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
  
  def to_param
    "#{self.division}-#{self.year}"
  end
  
end
