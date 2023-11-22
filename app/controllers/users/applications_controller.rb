class Users::ApplicationsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user

  def index
    @applications_with_signin = Doorkeeper::Application.not_api_only.can_signin(@user)
    @applications_without_signin = Doorkeeper::Application.not_api_only.without_signin_permission_for(@user)
  end

  private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize @user
  end
end
