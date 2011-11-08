class Calendar < ActiveRecord::Base     
  has_many :bank_holidays
                               
  default_scope order('year ASC')
  
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
      self.bank_holidays.each do |bh|
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
