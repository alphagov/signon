class Users::SigninPermissionsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  def create
    user = User.find(params[:user_id])

    authorize UserApplicationPermission.for(user, application)

    params = { supported_permission_ids: user.supported_permissions.map(&:id) + [application.signin_permission.id] }
    UserUpdate.new(user, params, current_user, user_ip_address).call

    redirect_to user_applications_path(user)
  end

private

  def application
    @application ||= Doorkeeper::Application.find(params[:application_id])
  end
end
