class Admin::UsersController < Admin::BaseController
  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  respond_to :html
  before_filter :set_user, only: [:edit, :update, :unlock, :resend_email_change, :cancel_email_change]

  def index
    @q = User.search(params[:q])
    if params[:q]
      @users = @q.result(distinct: true).order("name").page(params[:page]).per(100)
    else
      @users = User.order("name").alphabetical_group(params[:letter])
    end
  end

  def edit
  end

  def update
    email_before = @user.email
    if @user.update_attributes(translate_faux_signin_permission(params[:user]), as: current_user.role.to_sym)
      @user.permissions.reload
      results = PermissionUpdater.new(@user, @user.applications_used).attempt
      @successes, @failures = results[:successes], results[:failures]
      if @user.invited_but_not_yet_accepted? && (email_before != @user.email)
        @user.invite!
      end

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

  def resend_email_change
    @user.resend_confirmation_token
    if @user.errors.empty?
      redirect_to admin_users_path, notice: "Successfully resent email change email to #{@user.unconfirmed_email}"
    else
      redirect_to edit_admin_user_path(@user), alert: "Failed to send email change email"
    end
  end

  def cancel_email_change
    @user.unconfirmed_email = nil
    @user.confirmation_token = nil
    @user.save(validate: false)
    redirect_to edit_admin_user_path(@user)
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
