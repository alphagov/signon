class OauthUsersController < ApplicationController
  before_action :doorkeeper_authorize!
  before_action :validate_token_matches_client_id
  skip_after_action :verify_authorized

  def show
    current_resource_owner.permissions_synced!(application_making_request)
    respond_to do |format|
      format.json do
        presenter = UserOAuthPresenter.new(current_resource_owner, application_making_request)
        render json: presenter.as_hash.to_json
      end
    end
  end

private

  def validate_token_matches_client_id
    # FIXME: Once gds-sso is updated everywhere, this should always validate
    # the client_id param.  It should 401 if no client_id is given.
    if params[:client_id].present? && (params[:client_id] != doorkeeper_token.application.uid)
      head :unauthorized
    end
  end
end
