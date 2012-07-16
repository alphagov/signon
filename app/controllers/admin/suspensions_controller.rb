class Admin::SuspensionsController < Admin::BaseController
  before_filter :set_user

  respond_to :html

  def edit
  end

  def update
    if params[:user][:suspended] == "1"
      @user.suspend!(params[:user][:reason_for_suspension])
    else
      @user.unsuspend!
    end
    redirect_to admin_users_path, notice: "#{@user.name} is now #{@user.suspended? ? "Suspended" : "Active"}"
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
