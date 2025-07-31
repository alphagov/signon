class UserMailer < Devise::Mailer
  include MailerHelper
  append_view_path Rails.root.join("app/views/devise/mailer")

  default from: proc { email_from }

  helper_method :suspension_time, :account_name, :locked_time, :unlock_time

  def two_step_reset(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: "2-step verification has been reset")
  end

  def two_step_changed(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: "Your 2-step verification phone has been changed")
  end

  def two_step_enabled(user)
    prefix = "[#{GovukEnvironment.current.titleize}] " unless GovukEnvironment.current == "production"
    @user = user
    view_mail(template_id, to: @user.email, subject: "#{prefix}2-step verification set up")
  end

  def two_step_mandated(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: "Make your Signon account more secure")
  end

  def suspension_reminder(user, days)
    @user = user
    @days = days
    view_mail(template_id, to: @user.email, subject: suspension_reminder_subject)
  end

  def suspension_notification(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: suspension_notification_subject)
  end

  def notify_reset_password_disallowed_due_to_suspension(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: "Cannot reset password on suspended Signon GOV.UK #{account_name}")
  end

  def notify_reset_password_disallowed_due_to_unaccepted_invitation(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: "Cannot reset GOV.UK password on inactive Signon GOV.UK #{account_name}")
  end

  def email_changed_by_admin_notification(user, email_was, to_address)
    @user = user
    @email_was = email_was
    view_mail(template_id, to: to_address, subject: "Your #{app_name} login details have changed")
  end

  def email_changed_notification(user)
    @user = user
    view_mail(template_id, to: @user.email, subject: "Your #{app_name} email address is being changed")
  end

  def unlock_instructions(user, _token, _opts = {})
    @user = user
    view_mail(template_id, to: @user.email, subject: sprintf(t("devise.mailer.unlock_instructions.subject"), app_name:))
  end

  def reset_password_instructions(user, token, _opts = {})
    @user = user
    @token = token
    view_mail(template_id, to: @user.email, subject: t("devise.mailer.reset_password_instructions.subject"))
  end

  def confirmation_instructions(user, token, _opts = {})
    @user = user
    @token = token
    view_mail(template_id, to: @user.unconfirmed_email, subject: t("devise.mailer.confirmation_instructions.subject", account_name:))
  end

  def email_changed(user, _opts = {})
    @user = user
    view_mail(template_id, to: @user.email, subject: t("devise.mailer.email_changed.subject"))
  end

  def password_change(user, _opts = {})
    @user = user
    view_mail(template_id, to: @user.email, subject: t("devise.mailer.password_change.subject"))
  end

  def invitation_instructions(user, token, _opts = {})
    @user = user
    @token = token
    view_mail(template_id, to: @user.email, subject: t("devise.mailer.invitation_instructions.subject"))
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
    @user.locked_at.to_fs(:govuk_date)
  end

  def unlock_time
    t = (@user.locked_at + User.unlock_in)
    time_part = t.to_fs(:govuk_time)
    date_part = t.to_date.to_fs(:govuk_date)

    "#{time_part} UK time on #{date_part}"
  end

  def account_name
    "#{GovukEnvironment.current} account"
  end

  def subject_for(key)
    I18n.t(
      :"#{devise_mapping.name}_subject",
      scope: [:devise, :mailer, key],
      default: [:subject, key.to_s.humanize],
      app_name:,
    )
  end
end
