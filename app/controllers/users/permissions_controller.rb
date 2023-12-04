class Users::PermissionsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application

  def show
    authorize @user, :edit?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| @user.has_permission?(permission) ? 0 : 1 }
  end

  def edit
    authorize @user.signin_permission_for(@application)

    @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
  end

  def update
    authorize @user.signin_permission_for(@application)

    permission_ids_for_other_applications = @user.supported_permissions.excluding_application(@application).pluck(:id)
    user_update_params = { supported_permission_ids: permission_ids_for_other_applications + update_params[:supported_permission_ids].map(&:to_i) }
    UserUpdate.new(@user, user_update_params, current_user, user_ip_address).call

    flash[:application_id] = @application.id
    redirect_to user_applications_path(@user)
  end

private

  def update_params
    params.require(:application).permit(supported_permission_ids: [])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_application
    @application = Doorkeeper::Application.with_signin_permission_for(@user).not_api_only.find(params[:application_id])
  end
end