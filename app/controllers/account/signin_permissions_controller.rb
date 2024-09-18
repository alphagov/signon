class Account::SigninPermissionsController < ApplicationController
  before_action :authenticate_user!

  include ApplicationAccessHelper

  def create
    authorize [:account, Doorkeeper::Application], :grant_signin_permission?

    params = { supported_permission_ids: current_user.supported_permissions.map(&:id) + [application.signin_permission.id] }
    UserUpdate.new(current_user, params, current_user, user_ip_address).call

    flash[:success_alert] = { message: "Access granted", description: access_granted_description(application.id) }
    redirect_to account_applications_path
  end

  def delete
    authorize [:account, application], :remove_signin_permission?
  end

  def destroy
    authorize [:account, application], :remove_signin_permission?

    params = { supported_permission_ids: current_user.supported_permissions.map(&:id) - [application.signin_permission.id] }
    UserUpdate.new(current_user, params, current_user, user_ip_address).call

    flash[:success_alert] = { message: "Access removed", description: access_removed_description(application.id) }
    redirect_to account_applications_path
  end

private

  def application
    @application ||= Doorkeeper::Application.find(params[:application_id])
  end
end
