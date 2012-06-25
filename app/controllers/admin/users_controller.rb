class Admin::UsersController < Admin::BaseController
  respond_to :html
  before_filter :set_user, only: [:edit, :update, :unlock]
  before_filter :set_applications_and_permissions, only: [:edit]

  def index
    @users = User.order("created_at desc")
  end

  def edit
  end

  def update
    if @user.update_attributes(translate_faux_signin_permission(params[:user]), as: :admin)
      flash[:notice] = "Updated user #{@user.email} successfully"
      redirect_to admin_users_path
    else
      set_applications_and_permissions
      respond_with @user
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

    def set_applications_and_permissions
      @applications_and_permissions = ::Doorkeeper::Application.order(:name).all.map do |application|
        permission_for_application = @user.permissions.find_by_application_id(application.id)
        permission_for_application ||= Permission.new(application: application, user: @user)
        [application, permission_for_application]
      end
    end

    def translate_faux_signin_permission(raw_user_params)
      user_params = raw_user_params.dup
      if user_params[:permissions_attributes]
        user_params[:permissions_attributes].each do |index, attributes|
          attributes[:permissions] ||= []
          if attributes[:signin_permission] == "1"
            attributes[:permissions] << "signin"
          else
            has_signin = false
          end
          attributes.delete(:signin_permission)
        end
      end
      user_params
    end
end
