class Event
  attr_accessor :title, :date, :notes
  
  def initialize( attributes )
    self.title, self.date, self.notes = [ attributes[:title], attributes[:date], attributes[:notes] ]
  end
end
