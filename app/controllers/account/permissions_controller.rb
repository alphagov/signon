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

    supported_permission_ids = UserUpdatePermissionBuilder.new(
      user: current_user,
      updatable_permission_ids: @permissions.pluck(:id),
      selected_permission_ids: update_params[:supported_permission_ids].map(&:to_i),
    ).build

    UserUpdate.new(current_user, { supported_permission_ids: }).call

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
end
