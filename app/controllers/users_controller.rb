require 'csv'

class UsersController < ApplicationController
  include UserPermissionsControllerMethods

  before_action :authenticate_user!, except: :show
  before_action :load_and_authorize_user, except: [:index, :show]
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
        headers['Content-Disposition'] = 'attachment; filename="signon_users.csv"'
        render text: export, content_type: 'text/csv'
      end
    end
  end

  def edit
    @application_permissions = all_applications_and_permissions_for(@user)
  end

  def update
    raise Pundit::NotAuthorizedError if params[:user][:organisation_id].present? && !policy(@user).assign_organisations?

    updater = UserUpdate.new(@user, user_params, current_user)
    if updater.update
      redirect_to users_path, notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

  def unlock
    EventLog.record_event(@user, EventLog::MANUAL_ACCOUNT_UNLOCK, initiator: current_user)
    @user.unlock_access!
    flash[:notice] = "Unlocked #{@user.email}"
    redirect_to :back
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
    @user.save(validate: false)
    redirect_to :back
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
      render :edit_email_or_passphrase
    elsif @user.update_attributes(email: new_email)
      EventLog.record_email_change(@user, current_email, new_email)
      UserMailer.email_changed_notification(@user).deliver_later
      redirect_to root_path, notice: "An email has been sent to #{new_email}. Follow the link in the email to update your address."
    else
      flash[:alert] = "Failed to change email."
      render :edit_email_or_passphrase
    end
  end

  def update_passphrase
    if @user.update_with_password(password_params)
      EventLog.record_event(@user, EventLog::SUCCESSFUL_PASSPHRASE_CHANGE)
      flash[:notice] = t(:updated, scope: 'devise.passwords')
      bypass_sign_in(@user)
      redirect_to root_path
    else
      EventLog.record_event(@user, EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE)
      render :edit_email_or_passphrase
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
    @users = @users.filter(params[:filter]) if params[:filter].present?
    @users = @users.with_role(params[:role]) if can_filter_role?
    @users = @users.with_organisation(params[:organisation]) if params[:organisation].present?
    @users = @users.with_status(params[:status]) if params[:status].present?
    @users = @users.with_2sv_enabled(params[:two_step_status]) if params[:two_step_status].present?
  end

  def can_filter_role?
    params[:role].present? &&
      current_user.manageable_roles.include?(params[:role])
  end

  def should_include_permissions?
    params[:format] == 'csv'
  end

  def paginate_users
    if any_filter?
      if @users.is_a?(Array)
        @users = Kaminari.paginate_array(@users).page(params[:page]).per(100)
      else
        @users = @users.page(params[:page]).per(100)
      end
    else
      @users, @sorting_params = @users.alpha_paginate(
        params[:letter],
        ALPHABETICAL_PAGINATE_CONFIG,
        &:name
      )
    end
  end

  def any_filter?
    params[:filter].present? ||
      params[:role].present? ||
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
    params[:user][:supported_permission_ids] ||= []
  end

  def user_params
    UserParameterSanitiser.new(
      user_params: params.require(:user),
      current_user_role: current_user.role.to_sym,
    ).sanitise
  end

  def password_params
    params.require(:user).permit(
      :current_password,
      :password,
      :password_confirmation,
    )
  end
end
