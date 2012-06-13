class Admin::UsersController < Admin::BaseController
  respond_to :html

  def index
    @users = User.order("created_at desc")
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.attributes = params[:user]
    if params[:user][:is_admin]
      @user.is_admin = params[:user][:is_admin]
    end
    if @user.save
      flash[:notice] = "Updated user #{@user.email} successfully"
      redirect_to admin_users_path
    else
      respond_with @user
    end
  end
end
