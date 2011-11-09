Calendars::Application.routes.draw do
                             
  match '/bank-holidays', :to => 'calendar#index', :scope => 'bank_holidays', :as => :bank_holidays  
  match '/daylight-saving', :to => 'calendar#index', :scope => 'daylight_saving', :as => :daylight_saving
  
  match '/:scope/:id', :to => 'calendar#show', :as => :calendar

end
