class Superadmin::AuthorisationsController < ApplicationController
  include UserPermissionsControllerMethods

  before_filter :authenticate_user!
  before_filter :load_api_user
  authorize_resource class: 'Doorkeeper::AccessToken'

  respond_to :html

  def new
    @authorisation = @api_user.authorisations.build
  end

  def create
    authorisation = @api_user.authorisations.build(expires_in: ApiUser::DEFAULT_TOKEN_LIFE)
    authorisation.application_id = params[:doorkeeper_access_token][:application_id]

    if authorisation.save
      application_permission = @api_user.permissions.where(application_id: authorisation.application_id).first_or_create
      application_permission.permissions << "signin" unless application_permission.permissions.include?("signin")
      application_permission.save!

      EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_GENERATED, current_user, authorisation.application)
      flash[:authorisation] = { application_name: authorisation.application.name, token: authorisation.token }
    else
      flash[:error] = "There was an error while creating the access token"
    end
    redirect_to [:edit, :superadmin, @api_user]
  end

  def revoke
    authorisation = @api_user.authorisations.find(params[:id])
    if authorisation.revoke
      if params[:regenerate]
        regenerated_authorisation = @api_user.authorisations.create!(expires_in: ApiUser::DEFAULT_TOKEN_LIFE,
                                                                      application_id: authorisation.application_id)

        EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_REGENERATED, current_user, authorisation.application)
        flash[:authorisation] = { application_name: regenerated_authorisation.application.name,
                                  token: regenerated_authorisation.token }
      else
        EventLog.record_event(@api_user, EventLog::ACCESS_TOKEN_REVOKED, current_user, authorisation.application)
        flash[:notice] = "Access for #{authorisation.application.name} was revoked"
      end
    else
      flash[:error] = "There was an error while revoking access for #{authorisation.application.name}"
    end
    redirect_to [:edit, :superadmin, @api_user]
  end

private

  def load_api_user
    @api_user = ApiUser.find(params[:api_user_id])
  end
end
