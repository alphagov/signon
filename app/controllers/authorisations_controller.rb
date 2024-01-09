class AuthorisationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_api_user
  before_action :build_authorisation, only: %i[new create]
  before_action :load_authorisation, only: %i[edit revoke]
  before_action :authorize_authorisation

  respond_to :html

  def new; end

  def create
    @authorisation.application_id = params[:authorisation][:application_id]

    if @authorisation.save
      @api_user.grant_application_signin_permission(@authorisation.application)
      EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_GENERATED, initiator: current_user, application: @authorisation.application, ip_address: user_ip_address)
      flash[:authorisation] = { application_name: @authorisation.application.name, token: @authorisation.token }
    else
      flash[:error] = "There was an error while creating the access token"
    end
    redirect_to manage_tokens_api_user_path(@api_user)
  end

  def edit; end

  def revoke
    if @authorisation.revoke
      EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_REVOKED, initiator: current_user, application: @authorisation.application, ip_address: user_ip_address)
      flash[:notice] = "Access for #{@authorisation.application.name} was revoked"
    else
      flash[:error] = "There was an error while revoking access for #{@authorisation.application.name}"
    end
    redirect_to manage_tokens_api_user_path(@api_user)
  end

private

  def load_api_user
    @api_user = ApiUser.find(params[:api_user_id])
  end

  def build_authorisation
    @authorisation = @api_user.authorisations.build(expires_in: ApiUser::DEFAULT_TOKEN_LIFE)
  end

  def load_authorisation
    @authorisation = @api_user.authorisations.find(params[:id])
  end

  def authorize_authorisation
    authorize @authorisation, policy_class: AuthorisationPolicy
  end
end
