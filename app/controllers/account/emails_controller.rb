class Account::EmailsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!
  before_action :authorise_user

  def show; end

  def update
    current_email = current_user.email
    new_email = params[:user][:email]
    if current_email == new_email.strip
      flash[:alert] = "Nothing to update."
      render :show
    elsif current_user.update(email: new_email)
      EventLog.record_email_change(current_user, current_email, new_email)
      UserMailer.email_changed_notification(current_user).deliver_later
      redirect_to account_path, notice: email_change_notice
    else
      render :show
    end
  end

  def resend_email_change
    current_user.resend_confirmation_instructions
    if current_user.errors.empty?
      redirect_to account_path, notice: email_change_notice
    else
      redirect_to account_email_path, alert: "Failed to send email change email"
    end
  end

  def cancel_email_change
    current_user.cancel_email_change!

    redirect_to account_path, notice: "You have cancelled your pending email address change."
  end

private

  def authorise_user
    authorize %i[account emails]
  end

  def email_change_notice
    "An email has been sent to #{current_user.unconfirmed_email}. "\
    "Follow the link in the email to update your address."
  end
end
