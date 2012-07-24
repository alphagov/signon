class Admin::SuspensionsController < Admin::BaseController
  before_filter :set_user

  respond_to :html

  def edit
  end

  def update
    if params[:user][:suspended] == "1"
      @user.suspend!(params[:user][:reason_for_suspension])
      results = PropagateSuspension.new(@user, ::Doorkeeper::Application.all).attempt
      @successes, @failures = results[:successes], results[:failures]
    else
      @user.unsuspend!
      redirect_to admin_users_path
    end
    flash[:notice] = "#{@user.name} is now #{@user.suspended? ? "Suspended" : "Active"}"
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
