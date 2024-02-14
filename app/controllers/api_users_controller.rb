class ApiUsersController < ApplicationController
  include UserPermissionsControllerMethods

  before_action :authenticate_user!
  before_action :load_and_authorize_api_user, only: %i[edit manage_tokens]
  helper_method :api_user_applications_and_permissions, :visible_applications

  respond_to :html

  def index
    authorize ApiUser
    @api_users = ApiUser.includes(application_permissions: :application)
  end

  def new
    authorize ApiUser
    @api_user = ApiUser.new
  end

  def edit; end

  def manage_tokens; end

  def create
    authorize ApiUser

    @api_user = ApiUser.build(api_user_params_for_create)

    if @api_user.save
      EventLog.record_event(@api_user, EventLog::API_USER_CREATED, initiator: current_user, ip_address: user_ip_address)
      redirect_to edit_api_user_path(@api_user), notice: "Successfully created API user"
    else
      render :new
    end
  end

private

  def load_and_authorize_api_user
    @api_user = ApiUser.find(params[:id])
    authorize @api_user
  end

  def api_user_params_for_create
    sanitise(params.require(:api_user).permit(:name, :email))
  end

  def sanitise(permitted_user_params)
    UserParameterSanitiser.new(
      user_params: permitted_user_params.to_h,
      current_user_role: current_user.role_name.to_sym,
    ).sanitise
  end

  def api_user_applications_and_permissions(user)
    zip_permissions(visible_applications(user), user)
  end

  def visible_applications(user)
    user.authorised_applications.merge(Doorkeeper::AccessToken.not_revoked).includes(:supported_permissions)
  end
end
