Rails.application.routes.draw do
  get "/healthcheck", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::SidekiqRedis,
    GovukHealthcheck::ActiveRecord,
    Healthcheck::ApiTokens,
  )

  use_doorkeeper do
    controllers authorizations: "signin_required_authorizations"
  end

  devise_for :users, controllers: {
    invitations: "invitations",
    sessions: "sessions",
    passwords: "passwords",
    confirmations: "confirmations",
  }

  devise_scope :user do
    post "/users/invitation/resend/:id" => "invitations#resend", :as => "resend_user_invitation"
    put "/users/confirmation" => "confirmations#update"
    resource :two_step_verification, only: %i[show update],
      path: "/users/two_step_verification",
      controller: "devise/two_step_verification" do
      resource :session, only: %i[new create], controller: "devise/two_step_verification_session"

      member { get :prompt }
    end
  end

  resources :users, except: [:show] do
    member do
      get :edit_email_or_password
      patch :update_email
      patch :update_password
      post :unlock
      put :resend_email_change
      delete :cancel_email_change
      get :event_logs
      patch :reset_two_step_verification
    end
  end
  resource :user, only: [:show]

  resources :batch_invitations, only: %i[new create show]
  resources :bulk_grant_permission_sets, only: %i[new create show]
  resources :organisations, only: [:index]
  resources :suspensions, only: %i[edit update]

  resources :doorkeeper_applications, only: %i[index edit update] do
    member do
      get :users_with_access
    end
    resources :supported_permissions, only: %i[index new create edit update]
  end

  resources :api_users, only: %i[new create index edit update] do
    resources :authorisations, only: %i[new create] do
      member do
        post :revoke
      end
    end
  end

  # Gracefully handle GET on page (e.g. hit refresh) reached by a render to a POST
  match "/users/:id" => redirect("/users/%{id}/edit"), via: :get
  match "/suspensions/:id" => redirect("/users/%{id}/edit"), via: :get

  # compatibility with Sign-on-o-tron 1
  post "oauth/access_token" => "doorkeeper/tokens#create"

  get "/signin-required" => "root#signin_required"

  root to: "root#index"
end
