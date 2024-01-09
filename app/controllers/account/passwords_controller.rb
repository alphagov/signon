class Account::PasswordsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorise_user

  def edit; end

  def update
    if current_user.update_with_password(password_params)
      EventLog.record_event(current_user, EventLog::SUCCESSFUL_PASSWORD_CHANGE, ip_address: user_ip_address)
      flash[:notice] = t(:updated, scope: "devise.passwords")
      bypass_sign_in(current_user)
      redirect_to account_path
    else
      EventLog.record_event(current_user, EventLog::UNSUCCESSFUL_PASSWORD_CHANGE, ip_address: user_ip_address)
      render :edit
    end
  end

private

  def authorise_user
    authorize %i[account passwords]
  end

  def password_params
    params.require(:user).permit(
      :current_password,
      :password,
      :password_confirmation,
    )
  end
end
