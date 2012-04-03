Signonotron2::Application.routes.draw do
  devise_for :users

  resource :user, :only => [:show, :edit, :update]

  root :to => 'root#index'
end
