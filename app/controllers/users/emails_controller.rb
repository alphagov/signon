class Users::EmailsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user

  def edit; end

  def update
    updater = UserUpdate.new(@user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to edit_user_path(@user), notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize @user
  end

  def user_params
    UserParameterSanitiser.new(
      user_params: permitted_user_params,
      current_user_role: current_user.role.to_sym,
    ).sanitise
  end

  def permitted_user_params
    @permitted_user_params ||= params.require(:user).permit(:email).to_h
  end
end
