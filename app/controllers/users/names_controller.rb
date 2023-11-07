class Users::NamesController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user

  def edit; end

  def update
    updater = UserUpdate.new(@user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to user_path(@user), notice: "Updated user #{@user.email} successfully"
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
    permitted_user_params = current_user.role_class.permitted_user_params
    params.require(:user).permit(*permitted_user_params.intersection([:name]))
  end
end
