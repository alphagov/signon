Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::ActiveRecord,
    GovukHealthcheck::SidekiqRedis,
  )

  use_doorkeeper do
    controllers authorizations: "signin_required_authorizations"
    skip_controllers :applications, :authorized_applications, :token_info
  end
  post "/oauth/access_token" => "doorkeeper/tokens#create" # compatibility with OAuth v1

  devise_for :users,
             skip: :unlock,
             controllers: {
               invitations: "invitations",
               sessions: "sessions",
               passwords: "passwords",
               confirmations: "confirmations",
             }

  devise_scope :user do
    put "/users/confirmation" => "confirmations#update"
    resource :two_step_verification_session,
             only: %i[new create],
             path: "/users/two_step_verification_session",
             controller: "devise/two_step_verification_session"
    resource :two_step_verification,
             only: %i[show update],
             path: "/account/two_step_verification",
             controller: "devise/two_step_verification" do
      member { get :prompt }
    end
  end

  resources :users, except: [:show] do
    member do
      get :event_logs
      get :require_2sv
    end
    resource :name, only: %i[edit update], controller: "users/names"
    resource :email, only: %i[edit update], controller: "users/emails" do
      put :resend_email_change
      delete :cancel_email_change
    end
    resource :role, only: %i[edit update], controller: "users/roles"
    resource :organisation, only: %i[edit update], controller: "users/organisations"
    resource :two_step_verification_reset, only: %i[edit update], controller: "users/two_step_verification_resets"
    resource :two_step_verification_mandation, only: %i[edit update], controller: "users/two_step_verification_mandations"
    resource :invitation_resend, only: %i[edit update], controller: "users/invitation_resends"
    resource :unlocking, only: %i[edit update], controller: "users/unlockings"
    resources :applications, only: %i[index show], controller: "users/applications" do
      resource :permissions, only: %i[show edit update], controller: "users/permissions"
      resource :signin_permission, only: %i[create destroy], controller: "users/signin_permissions" do
        get :delete
      end
    end
  end
  get "user", to: "oauth_users#show"

  resource :account, only: [:show]
  namespace :account do
    resource :activity, only: [:show]
    resources :applications, only: %i[show index] do
      resource :permissions, only: %i[show edit update]
      resource :signin_permission, only: %i[create destroy] do
        get :delete
      end
    end
    resource :email, only: %i[edit update] do
      put :resend_email_change
      delete :cancel_email_change
    end
    resource :password, only: %i[edit update]
    resource :organisation, only: %i[edit update]
    resource :role, only: %i[edit update]
  end

  resources :batch_invitations, only: %i[new create show] do
    resource :permissions,
             only: %i[new create],
             controller: :batch_invitation_permissions
  end

  resources :organisations, only: %i[index edit update]
  resources :suspensions, only: %i[edit update]
  resources :two_step_verification_exemptions, only: %i[edit update]

  resources :doorkeeper_applications, only: %i[index edit update] do
    member do
      get :users_with_access
      get :access_logs
      get :monthly_access_stats
    end
    resources :supported_permissions, only: %i[index new create edit update destroy] do
      get :confirm_destroy, on: :member
    end
  end

  resources :api_users, only: %i[new create index edit] do
    resource :name, only: %i[edit update], controller: "users/names"
    resource :email, only: %i[edit update], controller: "users/emails"
    resources :applications, only: %i[index], controller: "api_users/applications" do
      resource :permissions, only: %i[edit update], controller: "api_users/permissions"
    end
    member do
      get :manage_tokens
    end
    resources :authorisations, only: %i[new create edit] do
      member do
        post :revoke
      end
    end
  end

  # Gracefully handle GET on page (e.g. hit refresh) reached by a render to a POST
  match "/users/:id" => redirect("/users/%{id}/edit"), via: :get
  match "/suspensions/:id" => redirect("/users/%{id}/edit"), via: :get

  get "/signin-required" => "root#signin_required"
  get "/privacy-notice" => "root#privacy_notice"
  get "/accessibility-statement" => "root#accessibility_statement"

  root to: "root#index"

  put "/user-research-recruitment/update" => "user_research_recruitment#update"

  get "/api/users" => "api/users#index"
end
