class Admin::SuspensionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  def update
    if params[:user][:suspended] == "1"
      succeeded = @user.suspend(params[:user][:reason_for_suspension])
      action = EventLog::ACCOUNT_SUSPENDED
    else
      succeeded = @user.unsuspend
      action = EventLog::ACCOUNT_UNSUSPENDED
    end

    if succeeded
      EventLog.record_event(@user, action, initiator: current_user)
      PermissionUpdater.perform_on(@user)
      ReauthEnforcer.perform_on(@user)

      flash[:notice] = "#{@user.name} is now #{@user.suspended? ? 'suspended' : 'active'}."

      redirect_to @user.api_user? ? edit_superadmin_api_user_path(@user) : edit_admin_user_path(@user)
    else
      flash[:alert] = "Failed"
      render :edit
    end
  end

end
