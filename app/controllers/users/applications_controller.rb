class Users::ApplicationsController < ApplicationController
  before_action :authenticate_user!

  def show
    user = User.find(params[:user_id])
    authorize user, :edit? # move this to applications policy but defer to this policy there (similar to what UserApplicationPermissionPolicy is doing, but more in the form of the Account::ApplicationPolicy)?

    redirect_to user_applications_path(user)
  end

  def index
    @user = User.find(params[:user_id])
    authorize @user, :edit? # move this to applications policy but defer to this policy there (similar to what UserApplicationPermissionPolicy is doing, but more in the form of the Account::ApplicationPolicy)?

    @applications_with_signin = Doorkeeper::Application.not_api_only.can_signin(@user)
    @applications_without_signin = Doorkeeper::Application.not_api_only.without_signin_permission_for(@user)
  end
end
