Signonotron2::Application.routes.draw do
  mount Doorkeeper::Engine => '/oauth'

  devise_for :users, :controllers => { 
    :invitations => 'admin/invitations',
    :passwords => 'passwords'
  } 

  devise_scope :user do
    post "/users/invitation/resend/:id" => "admin/invitations#resend", :as => "resend_user_invitation"
  end

  resource :user, :only => [:show, :edit, :update]

  namespace :admin do
    resources :users, except: [:show] do
      member do
        post :unlock
      end
    end

    resources :applications, only: [:index, :edit, :update]

    resources :suspensions, only: [:edit, :update]
    root :to => 'users#index'
  end

  # Gracefully handle GET on page (e.g. hit refresh) reached by a render to a POST
  match "/admin/users/:id" => redirect("/admin/users/%{id}/edit"), via: :get
  match "/admin/suspensions/:id" => redirect("/admin/users/%{id}/edit"), via: :get

  # compatibility with Sign-on-o-tron 1
  post "oauth/access_token" => "doorkeeper/tokens#create"

  root :to => 'root#index'
end
