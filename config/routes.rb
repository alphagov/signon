Signonotron2::Application.routes.draw do
  mount Doorkeeper::Engine => '/oauth'

  devise_for :users, :controllers => { :invitations => 'admin/invitations' }
  resource :user, :only => [:show, :edit, :update]

  namespace :admin do
    resources :users
  end

  # compatibility with Sign-on-o-tron 1
  post "oauth/access_token" => "doorkeeper/tokens#create"

  root :to => 'root#index'
end
