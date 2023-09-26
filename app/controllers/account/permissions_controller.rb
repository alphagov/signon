class Account::PermissionsController < ApplicationController
  include PermissionsHelper

  layout "admin_layout"

  before_action :authenticate_user!

  def index
    @application = Doorkeeper::Application.not_retired.find(params[:application_id])

    authorize current_user, :view_permissions?

    @permissions = permissions_for(@application).sort_by { |permission| current_user.has_permission?(permission) ? 0 : 1 }
  end
end
