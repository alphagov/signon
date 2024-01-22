class ApiUsers::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application
  before_action :set_permissions

  def edit
    authorize @api_user
  end

  def update
    authorize @api_user

    UserUpdate.new(@api_user, build_user_update_params(@api_user), current_user, user_ip_address).call

    flash[:application_id] = @application.id
    redirect_to api_user_applications_path(@api_user)
  end

private

  def update_params
    params.require(:application).permit(supported_permission_ids: [])
  end

  def set_user
    @api_user = ApiUser.find(params[:api_user_id])
  end

  def set_application
    @application = @api_user.authorised_applications.merge(Doorkeeper::AccessToken.not_revoked).find(params[:application_id])
  end

  def set_permissions
    @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
  end

  def build_user_update_params(user)
    permissions_user_has = user.supported_permissions.pluck(:id)
    updatable_permissions_for_this_app = @permissions.pluck(:id)
    selected_permissions = update_params[:supported_permission_ids].map(&:to_i)
    permissions_to_add = updatable_permissions_for_this_app.intersection(selected_permissions)
    permissions_to_remove = updatable_permissions_for_this_app.difference(selected_permissions)

    { supported_permission_ids: (permissions_user_has + permissions_to_add - permissions_to_remove).sort }
  end
end
