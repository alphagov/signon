Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::ActiveRecord,
    GovukHealthcheck::SidekiqRedis,
  )

  get "/healthcheck/api-tokens", to: "healthcheck#api_tokens"

  use_doorkeeper do
    controllers authorizations: "signin_required_authorizations"
    skip_controllers :applications, :authorized_applications, :token_info
  end

  devise_for :users,
             controllers: {
               invitations: "invitations",
               sessions: "sessions",
               passwords: "passwords",
               confirmations: "confirmations",
             }

  devise_scope :user do
    post "/users/invitation/resend/:id" => "invitations#resend", :as => "resend_user_invitation"
    put "/users/confirmation" => "confirmations#update"
    resource :two_step_verification,
             only: %i[show update],
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
      get :require_2sv
    end
  end
  resource :user, only: [:show]

  resources :batch_invitations, only: %i[new create show]
  resources :bulk_grant_permission_sets, only: %i[new create show]
  resources :organisations, only: %i[index edit update]
  resources :suspensions, only: %i[edit update]
  resources :two_step_verification_exemptions, only: %i[edit update]

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

  namespace :api do
    namespace :v1 do
      get "applications", to: "applications#show"
      post "applications", to: "applications#create"
      patch "applications/:id", to: "applications#update"
      get "api-users", to: "api_users#show"
      post "api-users", to: "api_users#create"
      post "api-users/:id/authorisations", to: "authorisations#create"
      post "api-users/:id/authorisations/test", to: "authorisations#test"
    end
  end

  # Gracefully handle GET on page (e.g. hit refresh) reached by a render to a POST
  match "/users/:id" => redirect("/users/%{id}/edit"), via: :get
  match "/suspensions/:id" => redirect("/users/%{id}/edit"), via: :get

  # compatibility with Signon 1
  post "oauth/access_token" => "doorkeeper/tokens#create"

  get "/signin-required" => "root#signin_required"

  root to: "root#index"
end
