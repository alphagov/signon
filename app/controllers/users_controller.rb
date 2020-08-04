require "csv"

class UsersController < ApplicationController
  include UserPermissionsControllerMethods

  layout "admin_layout", only: %w[edit_email_or_password]

  before_action :authenticate_user!, except: :show
  before_action :load_and_authorize_user, except: %i[index show]
  before_action :allow_no_application_access, only: [:update]
  helper_method :applications_and_permissions, :any_filter?
  respond_to :html

  before_action :doorkeeper_authorize!, only: :show
  before_action :validate_token_matches_client_id, only: :show
  skip_after_action :verify_authorized, only: :show

  def show
    current_resource_owner.permissions_synced!(application_making_request)
    respond_to do |format|
      format.json do
        presenter = UserOAuthPresenter.new(current_resource_owner, application_making_request)
        render json: presenter.as_hash.to_json
      end
    end
  end

  def index
    authorize User

    @users = policy_scope(User).includes(:organisation)
    filter_users if any_filter?
    respond_to do |format|
      format.html do
        paginate_users
      end
      format.csv do
        headers["Content-Disposition"] = 'attachment; filename="signon_users.csv"'
        render plain: export, content_type: "text/csv"
      end
    end
  end

  def edit
    @application_permissions = all_applications_and_permissions_for(@user)
  end

  def update
    raise Pundit::NotAuthorizedError if params[:user][:organisation_id].present? && !policy(@user).assign_organisations?

    updater = UserUpdate.new(@user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to users_path, notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

  def unlock
    EventLog.record_event(@user, EventLog::MANUAL_ACCOUNT_UNLOCK, initiator: current_user, ip_address: user_ip_address)
    @user.unlock_access!
    flash[:notice] = "Unlocked #{@user.email}"
    redirect_back(fallback_location: root_path)
  end

  def resend_email_change
    @user.resend_confirmation_instructions
    if @user.errors.empty?
      notice = if @user.normal?
                 "An email has been sent to #{@user.unconfirmed_email}. Follow the link in the email to update your address."
               else
                 "Successfully resent email change email to #{@user.unconfirmed_email}"
               end
      redirect_to root_path, notice: notice
    else
      redirect_to edit_user_path(@user), alert: "Failed to send email change email"
    end
  end

  def cancel_email_change
    @user.unconfirmed_email = nil
    @user.confirmation_token = nil
    @user.save!(validate: false)
    redirect_back(fallback_location: root_path)
  end

  def event_logs
    authorize @user
    @logs = @user.event_logs.page(params[:page]).per(100) if @user
  end

  def update_email
    current_email = @user.email
    new_email = params[:user][:email]
    if current_email == new_email.strip
      flash[:alert] = "Nothing to update."
      render :edit_email_or_password, layout: "admin_layout"
    elsif @user.update(email: new_email)
      EventLog.record_email_change(@user, current_email, new_email)
      UserMailer.email_changed_notification(@user).deliver_later
      redirect_to root_path, notice: "An email has been sent to #{new_email}. Follow the link in the email to update your address."
    else
      render :edit_email_or_password, layout: "admin_layout"
    end
  end

  def update_password
    if @user.update_with_password(password_params)
      EventLog.record_event(@user, EventLog::SUCCESSFUL_PASSWORD_CHANGE, ip_address: user_ip_address)
      flash[:notice] = t(:updated, scope: "devise.passwords")
      bypass_sign_in(@user)
      redirect_to root_path
    else
      EventLog.record_event(@user, EventLog::UNSUCCESSFUL_PASSWORD_CHANGE, ip_address: user_ip_address)
      render :edit_email_or_password, layout: "admin_layout"
    end
  end

  def reset_two_step_verification
    @user.reset_2sv!(current_user)
    UserMailer.two_step_reset(@user).deliver_later

    redirect_to :root, notice: "Reset 2-step verification for #{@user.email}"
  end

private

  def load_and_authorize_user
    @user = current_user.normal? ? current_user : User.find(params[:id])
    authorize @user
  end

  def filter_users
    @users = @users.filter_by_name(params[:filter]) if params[:filter].present?
    @users = @users.with_role(params[:role]) if can_filter_role?
    @users = @users.with_permission(params[:permission]) if params[:permission].present?
    @users = @users.with_organisation(params[:organisation]) if params[:organisation].present?
    @users = @users.with_status(params[:status]) if params[:status].present?
    @users = @users.with_2sv_enabled(params[:two_step_status]) if params[:two_step_status].present?
  end

  def can_filter_role?
    params[:role].present? &&
      current_user.manageable_roles.include?(params[:role])
  end

  def should_include_permissions?
    params[:format] == "csv"
  end

  def paginate_users
    if any_filter?
      @users = if @users.is_a?(Array)
                 Kaminari.paginate_array(@users).page(params[:page]).per(100)
               else
                 @users.page(params[:page]).per(100)
               end
    else
      @users, @sorting_params = @users.alpha_paginate(
        params.fetch(:letter, "A"),
        ALPHABETICAL_PAGINATE_CONFIG.dup,
        &:name
      )
    end
  end

  def any_filter?
    params[:filter].present? ||
      params[:role].present? ||
      params[:permission].present? ||
      params[:status].present? ||
      params[:organisation].present? ||
      params[:two_step_status].present?
  end

  def validate_token_matches_client_id
    # FIXME: Once gds-sso is updated everywhere, this should always validate
    # the client_id param.  It should 401 if no client_id is given.
    if params[:client_id].present?
      if params[:client_id] != doorkeeper_token.application.uid
        head :unauthorized
      end
    end
  end

  def export
    applications = Doorkeeper::Application.all
    CSV.generate do |csv|
      presenter = UserExportPresenter.new(applications)
      csv << presenter.header_row
      @users.includes(:organisation).find_each do |user|
        csv << presenter.row(user)
      end
    end
  end

  # When no permissions are selected for a user, we set the value to [] so
  # a user can have no permissions
  def allow_no_application_access
    params[:user] ||= {}
    params[:user][:supported_permission_ids] ||= []
  end

  def user_params
    UserParameterSanitiser.new(
      user_params: permitted_user_params,
      current_user_role: current_user.role.to_sym,
    ).sanitise
  end

  def permitted_user_params
    params.require(:user).permit(:user, :name, :email, :organisation_id, :require_2sv, :role, supported_permission_ids: []).to_h
  end

  def password_params
    params.require(:user).permit(
      :current_password,
      :password,
      :password_confirmation,
    )
  end
end
