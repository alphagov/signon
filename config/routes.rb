Signonotron2::Application.routes.draw do
  mount Doorkeeper::Engine => '/oauth'

  devise_for :users, :controllers => { :invitations => 'admin/invitations' } do
    post "/users/invitation/resend/:id" => "admin/invitations#resend", :as => "resend_user_invitation"
  end

  resource :user, :only => [:show, :edit, :update]

  namespace :admin do
    resources :users
  end

  # compatibility with Sign-on-o-tron 1
  post "oauth/access_token" => "doorkeeper/tokens#create"

  root :to => 'root#index'
end
