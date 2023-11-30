class Users::ApplicationsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  def index
    @user = User.find(params[:user_id])
    authorize @user, :edit?

    @applications_with_signin = Doorkeeper::Application.not_api_only.can_signin(@user)
    @applications_without_signin = Doorkeeper::Application.not_api_only.without_signin_permission_for(@user)
  end
end
