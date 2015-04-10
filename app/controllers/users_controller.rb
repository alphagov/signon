require 'csv'

class UsersController < ApplicationController
  include UserPermissionsControllerMethods

  before_filter :authenticate_user!, :except => :show
  before_filter :load_and_authorize_user, except: [:index, :show]
  helper_method :applications_and_permissions, :any_filter?
  respond_to :html

  before_filter :doorkeeper_authorize!, only: :show
  before_filter :validate_token_matches_client_id, :only => :show
  skip_after_filter :verify_authorized, only: :show

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

  def update
    raise Pundit::NotAuthorizedError if current_user.organisation_admin? &&
      ! current_user.organisation.subtree.map(&:id).include?(params[:user][:organisation_id].to_i)

    @user.skip_reconfirmation!
    if @user.update_attributes(user_params)
      @user.application_permissions.reload
      PermissionUpdater.perform_on(@user)

      if email_change = @user.previous_changes[:email]
        EventLog.record_email_change(@user, email_change.first, email_change.last, current_user)
        @user.invite! if @user.invited_but_not_yet_accepted?
        email_change.each do |to_address|
          UserMailer.delay.email_changed_by_admin_notification(@user, email_change.first, to_address)
        end
      end

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
    @user.resend_confirmation_token
    if @user.errors.empty?
      notice = @user.normal? ?
        "An email has been sent to #{@user.unconfirmed_email}. Follow the link in the email to update your address." :
        "Successfully resent email change email to #{@user.unconfirmed_email}"
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
    current_email, new_email = @user.email, params[:user][:email]
    if current_email == new_email.strip
      flash[:alert] = "Nothing to update."
      render :edit_email_or_passphrase
    elsif @user.update_attributes(email: new_email)
      EventLog.record_email_change(@user, current_email, new_email)
      UserMailer.email_changed_notification(@user).deliver
      redirect_to root_path, notice: "An email has been sent to #{new_email}. Follow the link in the email to update your address."
    else
      flash[:alert] = "Failed to change email."
      render :edit_email_or_passphrase
    end
  end

  def update_passphrase
    if @user.update_with_password(password_params)
      flash[:notice] = t(:updated, :scope => 'devise.passwords')
      sign_in(@user, :bypass => true)
      redirect_to root_path
    else
      EventLog.record_event(@user, EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE)
      render :edit_email_or_passphrase
    end
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
    @users = @users.select {|u| u.status == params[:status] } if params[:status].present?
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
      unless @users.kind_of?(Array)
        @users = @users.page(params[:page]).per(100)
      else
        @users = Kaminari.paginate_array(@users).page(params[:page]).per(100)
      end
    else
      @users, @sorting_params = @users.alpha_paginate(params[:letter], ALPHABETICAL_PAGINATE_CONFIG)
    end
  end

  def any_filter?
    params[:filter].present? || params[:role].present? || params[:status].present? || params[:organisation].present?
  end

  def application_making_request
    ::Doorkeeper::Application.find(doorkeeper_token.application_id)
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
    applications = Doorkeeper::Application.includes(:supported_permissions)
    CSV.generate do |csv|
      csv << UserExportPresenter.header_row(applications)
      @users.each do |user|
        csv << UserExportPresenter.new(user, applications).row
      end
    end
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
