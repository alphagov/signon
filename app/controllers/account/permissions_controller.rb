class Account::PermissionsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  def index
    @application = Doorkeeper::Application.not_retired.find(params[:application_id])

    authorize [:account, @application], :view_permissions?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| current_user.has_permission?(permission) ? 0 : 1 }
  end
end
