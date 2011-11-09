class CalendarData    

  def self.divisions
    @data = JSON.parse( File.read( File.expand_path('./lib/data/calendars.json') ) )
  
    @divisions = []
  
    @data['divisions'].each do |division|
      division_calendars = []
    
      division[1].each do |calendars|
        calendars.to_a.each do |cal| 
          holidays = []          
          calendar = { :year => cal[0], :division => division[0], :bank_holidays => [ ] }
                                                           
          cal[1].each do |event|
            calendar[:bank_holidays] << event.symbolize_keys
          end                   
        
          division_calendars << calendar                                                
        end                                                  
      
      end  
    
      @divisions << { :division => division[0], :calendars => division_calendars }
    end
      
    @divisions
  end
     
end              