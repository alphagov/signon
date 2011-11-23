class Event
  attr_accessor :title, :date, :notes

  def initialize(attributes)
    self.title = attributes[:title]
    self.date  = attributes[:date]
    self.notes = attributes[:notes]
  end
end
