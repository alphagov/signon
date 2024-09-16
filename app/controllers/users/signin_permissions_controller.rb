class Users::SigninPermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application, except: [:create]

  def create
    application = Doorkeeper::Application.not_api_only.find(params[:application_id])
    authorize [{ application:, user: @user }], :grant_signin_permission?, policy_class: Users::ApplicationPolicy

    params = { supported_permission_ids: @user.supported_permissions.map(&:id) + [application.signin_permission.id] }
    UserUpdate.new(@user, params, current_user, user_ip_address).call

    flash[:application_id] = application.id
    flash[:granting_access] = true
    redirect_to user_applications_path(@user)
  end

  def delete
    authorize [{ application: @application, user: @user }], :remove_signin_permission?, policy_class: Users::ApplicationPolicy
  end

  def destroy
    authorize [{ application: @application, user: @user }], :remove_signin_permission?, policy_class: Users::ApplicationPolicy

    params = { supported_permission_ids: @user.supported_permissions.map(&:id) - [@application.signin_permission.id] }
    UserUpdate.new(@user, params, current_user, user_ip_address).call

    flash[:application_id] = @application.id
    flash[:removing_access] = true

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
