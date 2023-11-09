class Account::PermissionsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :set_application

  def show
    authorize [:account, @application], :view_permissions?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| current_user.has_permission?(permission) ? 0 : 1 }
  end

  def edit
    authorize [:account, @application], :edit_permissions?

    @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
  end

  def update
    authorize [:account, @application], :edit_permissions?

    permission_ids_for_other_applications = current_user.supported_permissions.excluding_application(@application).pluck(:id)
    user_update_params = { supported_permission_ids: permission_ids_for_other_applications + params[:application][:supported_permission_ids] }
    UserUpdate.new(current_user, user_update_params, current_user, user_ip_address).call

    flash[:application_id] = @application.id
    redirect_to account_applications_path
  end

private

  def set_application
    @application = Doorkeeper::Application.not_api_only.find(params[:application_id])
  end
end
