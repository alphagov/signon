class UsersController < ApplicationController
  include UserPermissionsControllerMethods

  before_filter :authenticate_user!, :except => :show
  before_filter :load_and_authorize_user, except: [:index, :show]
  helper_method :applications_and_permissions, :any_filter?
  respond_to :html

  doorkeeper_for :show
  before_filter :validate_token_matches_client_id, :only => :show
  skip_after_filter :verify_authorized, only: :show

  def show
    relevant_permission.synced! if relevant_permission
    respond_to do |format|
      format.json do
        presenter = UserOAuthPresenter.new(current_resource_owner, application_making_request)
        render json: presenter.as_hash.to_json
      end
    end
  end

  def index
    authorize User

    @users = policy_scope(User)
    filter_users if any_filter?
    paginate_users
  end

  def update
    current_email, new_email = current_user.email, params[:user][:email]
    if current_user.normal?
      if current_email == new_email.strip
        flash[:alert] = "Nothing to update."
        render :edit
      elsif current_user.update_attributes(email: new_email)
        EventLog.record_email_change(current_user, current_email, new_email)
        UserMailer.email_changed_notification(current_user).deliver
        redirect_to root_path, notice: "An email has been sent to #{new_email}. Follow the link in the email to update your address."
      else
        flash[:alert] = "Failed to change email."
        render :edit
      end
    else
      authorize @user
      @user.skip_reconfirmation!
      if @user.update_attributes(translate_faux_signin_permission(params[:user]), as: current_user.role.to_sym)
        @user.permissions.reload
        PermissionUpdater.perform_on(@user)

        if email_change = @user.previous_changes[:email]
          EventLog.record_email_change(@user, email_change.first, email_change.last, current_user)
          @user.invite! if @user.invited_but_not_yet_accepted?
          email_change.each do |to_address|
            UserMailer.delay.email_changed_by_admin_notification(@user, email_change.first, to_address)
          end
        end

        redirect_to admin_users_path, notice: "Updated user #{@user.email} successfully"
      else
        render :edit
      end
    end
  end

  def unlock
    EventLog.record_event(@user, EventLog::MANUAL_ACCOUNT_UNLOCK, current_user)
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
    redirect_to edit_user_path(@user)
  end

  def event_logs
    authorize @user
    @logs = @user.event_logs.page(params[:page]).per(100) if @user
  end

  def update_passphrase
    params[:user] ||= {}
    password_params = params[:user].symbolize_keys.keep_if { |k, v| [:current_password, :password, :password_confirmation].include?(k) }
    if @user.update_with_password(password_params)
      flash[:notice] = t(:updated, :scope => 'devise.passwords')
      sign_in(@user, :bypass => true)
      redirect_to root_path
    else
      EventLog.record_event(@user, EventLog::UNSUCCESSFUL_PASSPHRASE_CHANGE)
      render :edit
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
    @users = @users.select {|u| u.status == params[:status] } if params[:status].present?
  end

  def can_filter_role?
    params[:role].present? &&
    current_user.manageable_roles.include?(params[:role])
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
    params[:filter].present? || params[:role].present? || params[:status].present?
  end

  def relevant_permission
    current_resource_owner
        .permissions
        .where(application_id: application_making_request.id)
        .first
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
end
