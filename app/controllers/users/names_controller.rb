class Users::NamesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user
  before_action :redirect_to_account_page_if_acting_on_own_user, only: %i[edit]

  helper_method :submit_path
  helper_method :return_path

  def edit; end

  def update
    updater = UserUpdate.new(@user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to return_path, notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

private

  def load_user
    @user = params[:api_user_id].present? ? ApiUser.find(params[:api_user_id]) : User.find(params[:user_id])
  end

  def authorize_user
    authorize @user
  end

  def user_params
    params.require(:user).permit(:name)
  end

  def redirect_to_account_page_if_acting_on_own_user
    redirect_to account_path if current_user == @user
  end

  def submit_path
    @user.api_user? ? api_user_name_path(@user) : user_name_path(@user)
  end

  def return_path
    @user.api_user? ? edit_api_user_path(@user) : edit_user_path(@user)
  end
end
