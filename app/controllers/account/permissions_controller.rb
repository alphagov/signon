class Account::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_application
  before_action :set_permissions

  def show
    authorize [:account, @application], :view_permissions?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| current_user.has_permission?(permission) ? 0 : 1 }
  end

  def edit
    authorize [:account, @application], :edit_permissions?
  end

  def update
    authorize [:account, @application], :edit_permissions?

    supported_permission_ids = build_user_update_params(current_user, @permissions.pluck(:id), update_params[:supported_permission_ids].map(&:to_i))
    UserUpdate.new(current_user, { supported_permission_ids: }, current_user, user_ip_address).call

    flash[:application_id] = @application.id
    redirect_to account_applications_path
  end

private

  def update_params
    params.require(:application).permit(supported_permission_ids: [])
  end

  def set_application
    @application = Doorkeeper::Application.not_api_only.find(params[:application_id])
  end

  def set_permissions
    @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
  end

  def build_user_update_params(user, updatable_permission_ids, selected_permission_ids)
    permissions_user_has = user.supported_permissions.pluck(:id)
    permissions_to_add = updatable_permission_ids.intersection(selected_permission_ids)
    permissions_to_remove = updatable_permission_ids.difference(selected_permission_ids)

    (permissions_user_has + permissions_to_add - permissions_to_remove).sort
  end
end
