class Users::EmailsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user
  before_action :authorize_user

  def edit; end

  def update
    updater = UserUpdate.new(@user, user_params, current_user, user_ip_address)
    if updater.call
      redirect_to edit_user_path(@user), notice: "Updated user #{@user.email} successfully"
    else
      render :edit
    end
  end

  def resend_email_change
    @user.resend_confirmation_instructions
    if @user.errors.empty?
      redirect_to edit_user_path(@user), notice: "Successfully resent email change email to #{@user.unconfirmed_email}"
    else
      redirect_to edit_user_email_path(@user), alert: "Failed to send email change email"
    end
  end

  def cancel_email_change
    @user.cancel_email_change!

    redirect_to edit_user_path(@user)
  end

private

  def load_user
    @user = User.find(params[:user_id])
  end

  def authorize_user
    authorize @user
  end

  def user_params
    UserParameterSanitiser.new(
      user_params: permitted_user_params,
      current_user_role: current_user.role.to_sym,
    ).sanitise
  end

  def permitted_user_params
    @permitted_user_params ||= params.require(:user).permit(:email).to_h
  end
end
