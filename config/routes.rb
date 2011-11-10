Calendars::Application.routes.draw do
  
  match '/:scope', :to => 'calendar#index', :as => :calendars                  
  
  match '/:scope/:division-:year', :to => 'calendar#show', :as => :calendar, :constraints => { :year => /[0-9]{4}/ }
  match '/:scope/:division', :to => 'calendar#index', :as => :division         

end
