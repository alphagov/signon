class Account::SigninPermissionsController < ApplicationController
  before_action :authenticate_user!

  def create
    authorize [:account, Doorkeeper::Application], :grant_signin_permission?

    params = { supported_permission_ids: current_user.supported_permissions.map(&:id) + [application.signin_permission.id] }
    UserUpdate.new(current_user, params, current_user, user_ip_address).call

    flash[:application_id] = application.id
    flash[:granting_access] = true
    redirect_to account_applications_path
  end

  def delete
    authorize [:account, application], :remove_signin_permission?
  end

  def destroy
    authorize [:account, application], :remove_signin_permission?

    params = { supported_permission_ids: current_user.supported_permissions.map(&:id) - [application.signin_permission.id] }
    UserUpdate.new(current_user, params, current_user, user_ip_address).call

    redirect_to account_applications_path
  end

private

  def application
    @application ||= Doorkeeper::Application.find(params[:application_id])
  end
end
