class Users::SigninPermissionsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :load_user
  before_action :set_application

  def create
    authorize SigninPermission

    params = { supported_permission_ids: @user.supported_permissions.map(&:id) + [@application.signin_permission.id] }
    UserUpdate.new(@user, params, current_user, user_ip_address).call

    redirect_to user_applications_path(@user)
  end

  def delete
    authorize @user.signin_permission_for(@application)
  end

  def destroy
    authorize @user.signin_permission_for(@application)

    params = { supported_permission_ids: @user.supported_permissions.map(&:id) - [@application.signin_permission.id] }
    UserUpdate.new(@user, params, current_user, user_ip_address).call

    redirect_to user_applications_path(@user)
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def set_application
    @application ||= Doorkeeper::Application.find(params[:application_id])
  end
end
