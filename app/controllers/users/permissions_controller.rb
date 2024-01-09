class Users::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application
  before_action :set_permissions, only: %i[edit update]

  def show
    authorize @user, :edit?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| @user.has_permission?(permission) ? 0 : 1 }
  end

  def edit
    authorize UserApplicationPermission.for(@user, @application)
  end

  def update
    authorize UserApplicationPermission.for(@user, @application)

    UserUpdate.new(@user, build_user_update_params, current_user, user_ip_address).call

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

  def set_permissions
    @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
  end

  def build_user_update_params
    permissions_user_has = @user.supported_permissions.pluck(:id)
    updatable_permissions_for_this_app = @permissions.pluck(:id)
    selected_permissions = update_params[:supported_permission_ids].map(&:to_i)
    permissions_to_add = updatable_permissions_for_this_app.intersection(selected_permissions)
    permissions_to_remove = updatable_permissions_for_this_app.difference(selected_permissions)

    { supported_permission_ids: (permissions_user_has + permissions_to_add - permissions_to_remove).sort }
  end
end
