class Account::EmailPasswordsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :authorise_user

  def show; end

  def update_email
    current_email = current_user.email
    new_email = params[:user][:email]
    if current_email == new_email.strip
      flash[:alert] = "Nothing to update."
      render :show
    elsif current_user.update(email: new_email)
      EventLog.record_email_change(current_user, current_email, new_email)
      UserMailer.email_changed_notification(current_user).deliver_later
      redirect_to root_path, notice: "An email has been sent to #{new_email}. Follow the link in the email to update your address."
    else
      render :show
    end
  end

  def update_password
    if current_user.update_with_password(password_params)
      EventLog.record_event(current_user, EventLog::SUCCESSFUL_PASSWORD_CHANGE, ip_address: user_ip_address)
      flash[:notice] = t(:updated, scope: "devise.passwords")
      bypass_sign_in(current_user)
      redirect_to root_path
    else
      EventLog.record_event(current_user, EventLog::UNSUCCESSFUL_PASSWORD_CHANGE, ip_address: user_ip_address)
      render :show
    end
  end

private

  def authorise_user
    authorize %i[account email_passwords]
  end

  def password_params
    params.require(:user).permit(
      :current_password,
      :password,
      :password_confirmation,
    )
  end
end
