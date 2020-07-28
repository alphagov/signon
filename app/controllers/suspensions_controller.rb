class SuspensionsController < ApplicationController
  before_action :authenticate_user!, :load_and_authorize_user
  respond_to :html

  rescue_from ActiveRecord::RecordInvalid, with: :render_edit

  def update
    if params[:user][:suspended] == "1"
      succeeded = @user.suspend(params[:user][:reason_for_suspension])
      action = EventLog::ACCOUNT_SUSPENDED
    else
      succeeded = @user.unsuspend
      action = EventLog::ACCOUNT_UNSUSPENDED
    end

    if succeeded
      EventLog.record_event(@user, action, initiator: current_user, ip_address: user_ip_address)
      PermissionUpdater.perform_on(@user)
      ReauthEnforcer.perform_on(@user)

      flash[:notice] = "#{@user.email} is now #{@user.suspended? ? 'suspended' : 'active'}."

      redirect_to @user.api_user? ? edit_api_user_path(@user) : edit_user_path(@user)
    else
      render_edit
    end
  end

private

  def load_and_authorize_user
    @user = User.find(params[:id])
    authorize @user, :suspension?
  end

  def render_edit
    flash[:alert] = "Failed"
    render :edit
  end
end
