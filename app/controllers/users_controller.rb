require "csv"

class UsersController < ApplicationController
  include UserPermissionsControllerMethods

  layout "admin_layout"

  before_action :authenticate_user!
  before_action :load_user, except: %i[index]
  before_action :redirect_to_account_page_if_acting_on_own_user, only: %i[edit]
  before_action :authorize_user, except: %i[index]
  before_action :redirect_legacy_filters, only: [:index]
  helper_method :applications_and_permissions, :filter_params
  respond_to :html

  def index
    authorize User

    @filter = UsersFilter.new(policy_scope(User), current_user, filter_params)

    respond_to do |format|
      format.html do
        @users = @filter.paginated_users
      end
      format.csv do
        @users = @filter.users
        headers["Content-Disposition"] = 'attachment; filename="signon_users.csv"'
        render plain: export, content_type: "text/csv"
      end
    end
  end

  def edit; end

  def update
    UserUpdate.new(@user, user_params, current_user, user_ip_address).call
    redirect_to users_path, notice: "Updated user #{@user.email} successfully"
  end

  def event_logs
    authorize @user
    @logs = @user.event_logs.page(params[:page]).per(100) if @user
  end

  def require_2sv; end

private

  def load_user
    @user = User.find(params[:id])
  end

  def authorize_user
    authorize @user
  end

  def should_include_permissions?
    params[:format] == "csv"
  end

  def export
    applications = Doorkeeper::Application.all
    CSV.generate do |csv|
      presenter = UserExportPresenter.new(applications)
      csv << presenter.header_row
      @users.find_each do |user|
        csv << presenter.row(user)
      end
    end
  end

  def user_params
    UserParameterSanitiser.new(
      user_params: params.require(:user).permit(:require_2sv).to_h,
      current_user_role: current_user.role.to_sym,
    ).sanitise
  end

  def filter_params
    params.permit(
      :filter, :page, :format, :"option-select-filter",
      *LegacyUsersFilter::PARAM_KEYS,
      **UsersFilter::PERMITTED_CHECKBOX_FILTER_PARAMS
    ).except(:"option-select-filter")
  end

  def redirect_legacy_filters
    filter = LegacyUsersFilter.new(filter_params)
    if filter.redirect?
      redirect_to users_path(filter.options)
    end
  end

  def redirect_to_account_page_if_acting_on_own_user
    redirect_to account_path if current_user == @user
  end
end
