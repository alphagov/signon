class Users::NamesController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user
  before_action :redirect_to_account_page_if_acting_on_own_user, only: %i[edit]

  def edit; end

  def update
    if @user.update(user_params)
      EventLog.record_event(@user, EventLog::ACCOUNT_UPDATED, initiator: current_user, ip_address: user_ip_address)
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
    params.require(:user).permit(*current_user.permitted_params.intersection([:name]))
  end

  def redirect_to_account_page_if_acting_on_own_user
    redirect_to account_path if current_user == @user
  end
end
