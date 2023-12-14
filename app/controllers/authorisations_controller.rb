class AuthorisationsController < ApplicationController
  include UserPermissionsControllerMethods

  layout "admin_layout", only: %w[new]

  before_action :authenticate_user!
  before_action :load_and_authorize_api_user

  respond_to :html

  def new
    @authorisation = @api_user.authorisations.build
  end

  def create
    authorisation = @api_user.authorisations.build(expires_in: ApiUser::DEFAULT_TOKEN_LIFE)
    authorisation.application_id = params[:doorkeeper_access_token][:application_id]

    if authorisation.save
      @api_user.grant_application_signin_permission(authorisation.application)
      EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_GENERATED, initiator: current_user, application: authorisation.application, ip_address: user_ip_address)
      flash[:authorisation] = { application_name: authorisation.application.name, token: authorisation.token }
    else
      flash[:error] = "There was an error while creating the access token"
    end
    redirect_to manage_tokens_api_user_path(@api_user)
  end

  def revoke
    authorisation = @api_user.authorisations.find(params[:id])
    if authorisation.revoke
      EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_REVOKED, initiator: current_user, application: authorisation.application, ip_address: user_ip_address)
      flash[:notice] = "Access for #{authorisation.application.name} was revoked"
    else
      flash[:error] = "There was an error while revoking access for #{authorisation.application.name}"
    end
    redirect_to manage_tokens_api_user_path(@api_user)
  end

private

  def load_and_authorize_api_user
    @api_user = ApiUser.find(params[:api_user_id])
    authorize @api_user
  end
end
