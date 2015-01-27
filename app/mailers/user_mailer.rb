class UserMailer < ActionMailer::Base
  include MailerHelper

  default from: lambda { email_from }

  helper_method :suspension_time, :account_name, :instance_name, :locked_time, :unlock_time

  def suspension_reminder(user, days)
    @user, @days = user, days
    mail(to: @user.email, subject: suspension_reminder_subject)
  end

  def suspension_notification(user)
    @user = user
    mail(to: @user.email, subject: suspension_notification_subject)
  end

  def locked_account_explanation(user)
    @user = user
    mail(to: @user.email, subject: locked_account_explanation_subject)
  end

  def notify_reset_password_disallowed_due_to_suspension(user)
    @user = user
    mail(to: @user.email, subject: suspension_notification_subject)
  end

  def email_changed_by_admin_notification(user, email_was, to_address)
    @user, @email_was = user, email_was
    mail(to: to_address, subject: "Your #{app_name} email address has been updated")
  end

  def email_changed_notification(user)
    @user = user
    mail(to: @user.email, subject: "Your #{app_name} email address is being changed")
  end

private
  def suspension_time
    if @days == 1
      "tomorrow"
    else
      "in #{@days} days"
    end
  end

  def suspension_reminder_subject
    "Your #{app_name} account will be suspended #{suspension_time}"
  end

  def suspension_notification_subject
    "Your #{app_name} account has been suspended"
  end

  def locked_account_explanation_subject
    "Your #{app_name} account has been locked"
  end

  def locked_time
    @user.locked_at.to_s(:govuk_date)
  end

  def unlock_time
    (@user.locked_at + 1.hour).to_s(:govuk_date)
  end

  def account_name
    if instance_name.present?
      "#{instance_name} account"
    else
      "account"
    end
  end
end
