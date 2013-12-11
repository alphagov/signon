class Admin::SuspensionsController < ApplicationController
  before_filter :authenticate_user!
  load_resource :user, parent: false
  authorize_resource :user, parent:false, only: :edit

  respond_to :html

  def update
    if params[:user][:suspended] == "1"
      authorize! :suspend, @user
      succeeded = @user.suspend(params[:user][:reason_for_suspension])
    else
      authorize! :unsuspend, @user
      succeeded = @user.unsuspend
    end

    if succeeded
      results = SuspensionUpdater.new(@user, @user.applications_used).attempt
      @successes, @failures = results[:successes], results[:failures]
      flash[:notice] = "#{@user.name} is now #{@user.suspended? ? "suspended" : "active"}"
    else
      flash[:alert] = "Failed"
      render :edit
    end
  end

end
