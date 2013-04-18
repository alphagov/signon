class Admin::SuspensionsController < Admin::BaseController
  before_filter :set_user

  respond_to :html

  def edit
  end

  def update
    if params[:user][:suspended] == "1"
      succeeded = @user.suspend(params[:user][:reason_for_suspension])
    else
      succeeded = @user.unsuspend
    end

    if succeeded
      results = SuspensionUpdater.new(@user, @user.applications_used).attempt
      @successes, @failures = results[:successes], results[:failures]
      flash[:notice] = "#{@user.name} is now #{@user.suspended? ? "Suspended" : "Active"}"
    else
      flash[:alert] = "Failed"
      render :edit
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
