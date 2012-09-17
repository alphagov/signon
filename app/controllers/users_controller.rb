class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => :show
  doorkeeper_for :show

  def show
    relevant_permission.synced!
    respond_to do |format|
      format.json do
        render json: current_resource_owner.to_sensible_json(application_making_request)
      end
    end
  end

  def edit
  end

  def update
    params[:user] ||= {}
    password_params = params[:user].symbolize_keys.keep_if { |k, v| [:current_password, :password, :password_confirmation].include?(k) }
    if current_user.update_with_password(password_params)
      flash[:notice] = t(:updated, :scope => 'devise.passwords')
      sign_in(current_user, :bypass => true)
      redirect_to root_path
    else
      render :edit
    end
  end

  private
    def relevant_permission
      current_resource_owner
          .permissions
          .where(application_id: application_making_request.id)
          .first
    end

    def application_making_request
      ::Doorkeeper::Application.find(doorkeeper_token.application_id)
    end
end
