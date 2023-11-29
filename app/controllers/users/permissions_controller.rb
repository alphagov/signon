class Users::PermissionsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :set_application

  def show
    @user = User.find(params[:user_id])
    authorize @user, :edit?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| @user.has_permission?(permission) ? 0 : 1 }
  end

private

  def set_application
    @application = Doorkeeper::Application.not_api_only.find(params[:application_id])
  end
end
