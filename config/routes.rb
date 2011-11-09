Calendars::Application.routes.draw do
                             
  match '/calendars', :to => 'calendar#index', :as => :calendars 
  match '/calendars/:id', :to => 'calendar#show', :as => :calendar

end
