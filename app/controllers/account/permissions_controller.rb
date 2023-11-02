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

    @permissions = @application.sorted_supported_permissions_grantable_from_ui
  end

  def update
    authorize [:account, @application], :edit_permissions?

    current_user.replace_application_permissions(@application, params[:application][:permissions])
    redirect_to account_applications_path
  end

private

  def set_application
    @application = Doorkeeper::Application.not_api_only.find(params[:application_id])
  end
end
