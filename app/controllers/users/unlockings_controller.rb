class Users::UnlockingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user
  before_action :redirect_if_already_unlocked

  def edit; end

  def update
    @user.unlock_access!
    EventLog.record_event(@user, EventLog::MANUAL_ACCOUNT_UNLOCK, initiator: current_user, ip_address: user_ip_address)
    flash[:notice] = "Unlocked #{@user.email}"
    redirect_to edit_user_path(@user)
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize(@user, :unlock?)
  end

  def redirect_if_already_unlocked
    unless @user.access_locked?
      flash[:notice] = "#{@user.email} is already unlocked"
      redirect_to edit_user_path(@user)
    end
  end
end
