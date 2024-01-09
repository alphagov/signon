class ApiUsers::ApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @api_user = ApiUser.find(params[:api_user_id])

    authorize @api_user

    @applications = @api_user.authorised_applications.merge(Doorkeeper::AccessToken.not_revoked)
  end
end
