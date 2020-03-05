class UserMailer < Devise::Mailer
  include MailerHelper
  append_view_path Rails.root.join("app/views/devise/mailer")

  default from: Proc.new { email_from }

  helper_method :suspension_time, :account_name, :instance_name, :locked_time, :unlock_time, :production?

  def two_step_reset(user)
    @user = user
    mail(to: @user.email, subject: "2-step verification has been reset")
  end

  def two_step_changed(user)
    @user = user
    mail(to: @user.email, subject: "Your 2-step verification phone has been changed")
  end

  def two_step_enabled(user)
    prefix = "[#{Rails.application.config.instance_name.titleize}] " unless production?
    @user = user
    mail(to: @user.email, subject: "#{prefix}2-step verification set up")
  end

  def two_step_flagged(user)
    @user = user
    mail(to: @user.email, subject: "Make your Signon account more secure")
  end

  def suspension_reminder(user, days)
    @user = user
    @days = days
    mail(to: @user.email, subject: suspension_reminder_subject)
  end

  def suspension_notification(user)
    @user = user
    mail(to: @user.email, subject: suspension_notification_subject)
  end

  def notify_reset_password_disallowed_due_to_suspension(user)
    @user = user
    mail(to: @user.email, subject: suspension_notification_subject)
  end

  def notify_reset_password_disallowed_due_to_unaccepted_invitation(user)
    @user = user
    mail(to: @user.email, subject: "Your #{app_name} account has not been activated")
  end

  def email_changed_by_admin_notification(user, email_was, to_address)
    @user = user
    @email_was = email_was
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

  def subject_for(key)
    I18n.t(:"#{devise_mapping.name}_subject", scope: [:devise, :mailer, key],
      default: [:subject, key.to_s.humanize], app_name: app_name)
  end

  def production?
    Rails.application.config.instance_name.blank?
  end
end
