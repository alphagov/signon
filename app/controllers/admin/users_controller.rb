class Admin::UsersController < ApplicationController
  include UserPermissionsControllerMethods

  before_filter :authenticate_user!
  load_and_authorize_resource

  helper_method :applications_and_permissions, :any_filter?

  respond_to :html

  def index
    @users = @users.web_users
    filter_users if any_filter?
    paginate_users
  end

  def update
    authorize! :read, Organisation.find(params[:user][:organisation_id]) if params[:user][:organisation_id].present?

    @user.skip_reconfirmation!
    if @user.update_attributes(translate_faux_signin_permission(params[:user]), as: current_user.role.to_sym)
      @user.permissions.reload
      PermissionUpdater.perform_on(@user)

      if email_change = @user.previous_changes[:email]
        EventLog.record_event(@user, EventLog::EMAIL_CHANGE_INITIATIED, current_user)
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

  def unlock
    EventLog.record_event(@user, EventLog::MANUAL_ACCOUNT_UNLOCK, current_user)
    @user.unlock_access!
    flash[:notice] = "Unlocked #{@user.email}"
    redirect_to :back
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

  def filter_users
    @users = @users.filter(params[:filter]) if params[:filter].present?
    @users = @users.with_role(params[:role]) if can_filter_role?
    @users = @users.select{|u| u.status == params[:status]} if params[:status].present?
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

end
