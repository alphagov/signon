class BankHoliday < ActiveRecord::Base            
  default_scope order('date ASC')
end
