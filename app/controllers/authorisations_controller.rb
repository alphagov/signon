class AuthorisationsController < ApplicationController
  include UserPermissionsControllerMethods

  before_filter :authenticate_user!
  before_filter :load_and_authorize_api_user

  respond_to :html

  def new
    @authorisation = @api_user.authorisations.build
  end

  def create
    authorisation = @api_user.authorisations.build(expires_in: ApiUser::DEFAULT_TOKEN_LIFE)
    authorisation.application_id = params[:doorkeeper_access_token][:application_id]

    if authorisation.save
      @api_user.grant_application_permission(authorisation.application, 'signin')
      EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_GENERATED, initiator: current_user, application: authorisation.application)
      flash[:authorisation] = { application_name: authorisation.application.name, token: authorisation.token }
    else
      flash[:error] = "There was an error while creating the access token"
    end
    redirect_to [:edit, @api_user]
  end

  def revoke
    authorisation = @api_user.authorisations.where(id: params[:id]).first
    if authorisation.revoke
      if params[:regenerate]
        regenerated_authorisation = @api_user.authorisations.create!(expires_in: ApiUser::DEFAULT_TOKEN_LIFE,
                                                                      application_id: authorisation.application_id)

        EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_REGENERATED, initiator: current_user, application: authorisation.application)
        flash[:authorisation] = { application_name: regenerated_authorisation.application.name,
                                  token: regenerated_authorisation.token }
      else
        EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_REVOKED, initiator: current_user, application: authorisation.application)
        flash[:notice] = "Access for #{authorisation.application.name} was revoked"
      end
    else
      flash[:error] = "There was an error while revoking access for #{authorisation.application.name}"
    end
    redirect_to [:edit, @api_user]
  end

private

  def load_and_authorize_api_user
    @api_user = ApiUser.where(id: params[:api_user_id]).first
    authorize @api_user
  end
end
