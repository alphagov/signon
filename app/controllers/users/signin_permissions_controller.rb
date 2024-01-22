class Users::SigninPermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application, except: [:create]

  def create
    application = Doorkeeper::Application.not_api_only.find(params[:application_id])
    authorize UserApplicationPermission.for(@user, application)

    params = { supported_permission_ids: @user.supported_permissions.map(&:id) + [application.signin_permission.id] }
    UserUpdate.new(@user, params, current_user, user_ip_address).call

    redirect_to user_applications_path(@user)
  end

  def delete
    authorize UserApplicationPermission.for(@user, @application)
  end

  def destroy
    authorize UserApplicationPermission.for(@user, @application)

    params = { supported_permission_ids: @user.supported_permissions.map(&:id) - [@application.signin_permission.id] }
    UserUpdate.new(@user, params, current_user, user_ip_address).call

    redirect_to user_applications_path(@user)
  end

private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_application
    @application = Doorkeeper::Application.with_signin_permission_for(@user).not_api_only.find(params[:application_id])
  end
end
