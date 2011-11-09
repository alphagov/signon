Calendars::Application.routes.draw do
                             
  match '/bank-holidays', :to => 'calendar#index', :scope => 'bank_holidays', :as => :bank_holidays  
  
  match '/:scope/:id', :to => 'calendar#show', :as => :calendar

end
