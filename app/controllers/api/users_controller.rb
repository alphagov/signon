class Api::UsersController < ApplicationController
  before_action :doorkeeper_authorize!, :check_signon_permissions
  skip_after_action :verify_authorized

  def index
    users = User.where(uid: params[:uuids])
    render json: Api::UserPresenter.present_many(users)
  end

private

  def check_signon_permissions
    head :unauthorized unless doorkeeper_token&.application&.signon?
  end
end
