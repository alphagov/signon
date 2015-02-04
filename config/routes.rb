Signonotron2::Application.routes.draw do
  use_doorkeeper

  devise_for :users, :controllers => {
    :invitations => 'invitations',
    :sessions => 'sessions',
    :passwords => 'passwords',
    :confirmations => 'confirmations'
  }

  devise_scope :user do
    post "/users/invitation/resend/:id" => "invitations#resend", :as => "resend_user_invitation"
    put "/users/confirmation" => "confirmations#update"
  end

  resources :users, except: [:show] do
    member do
      get :edit_email_or_passphrase
      put :update_email
      put :update_passphrase
      post :unlock
      put :resend_email_change
      delete :cancel_email_change
      get :event_logs
    end
  end
  resource :user, only: [:show]

  resources :batch_invitations, only: [:new, :create, :show]
  resources :organisations, only: [:index]
  resources :suspensions, only: [:edit, :update]

  resources :doorkeeper_applications, only: [:index, :edit, :update] do
    resources :supported_permissions, only: [:index, :new, :create, :edit, :update]
  end

  resources :api_users, only: [:new, :create, :index, :edit, :update] do
    resources :authorisations, only: [:new, :create] do
      member do
        # revoke is a GET request so that we don't have to use
        # `link_to 'Revoke' ... method: :delete`, which works
        # only with javascript
        get :revoke
      end
    end
  end

  # Gracefully handle GET on page (e.g. hit refresh) reached by a render to a POST
  match "/users/:id" => redirect("/users/%{id}/edit"), via: :get
  match "/suspensions/:id" => redirect("/users/%{id}/edit"), via: :get

  # compatibility with Sign-on-o-tron 1
  post "oauth/access_token" => "doorkeeper/tokens#create"

  root :to => 'root#index'
end
