Calendars::Application.routes.draw do
                             
  match '/calendar', :to => 'calendar#index' 
  match '/calendar/:id', :to => 'calendar#show', :as => :calendar

  root :to => 'calendar#index'

end
