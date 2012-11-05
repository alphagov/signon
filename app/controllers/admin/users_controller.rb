class Admin::UsersController < Admin::BaseController
  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  respond_to :html
  before_filter :set_user, only: [:edit, :update, :unlock]

  def index
    if params[:filter]
      @users = User.order("name")
                    .where("email like ? or name like ?", "%#{params[:filter]}%", "%#{params[:filter]}%")
                    .page(params[:page])
                    .per(100)
    else
      @users = User.order("name").alphabetical_group(params[:letter])
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(translate_faux_signin_permission(params[:user]), as: :admin)
      @user.permissions.reload
      results = PermissionUpdater.new(@user, @user.applications_used).attempt
      @successes, @failures = results[:successes], results[:failures]

      flash[:notice] = "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

  def unlock
    @user.unlock_access!
    flash[:notice] = "Unlocked #{@user.email}"
    redirect_to admin_users_path
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
