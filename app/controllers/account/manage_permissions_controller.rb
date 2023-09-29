class Account::ManagePermissionsController < ApplicationController
  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  before_action :authenticate_user!
  before_action :authorise_user

  def show
    @application_permissions = all_applications_and_permissions_for(current_user)
  end

  def update
    updater = UserUpdate.new(current_user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to root_path, notice: "Your permissions have been updated."
    else
      @application_permissions = all_applications_and_permissions_for(current_user)
      render :show
    end
  end

private

  def authorise_user
    authorize %i[account manage_permissions]
  end

  def user_params
    UserParameterSanitiser.new(
      user_params: permitted_user_params,
      current_user_role: current_user.role.to_sym,
    ).sanitise
  end

  def permitted_user_params
    params.fetch(:user, {}).permit(supported_permission_ids: []).to_h
  end
end
