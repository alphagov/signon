class UserMailer < ActionMailer::Base
  helper_method :suspension_time, :account_name

  default from: "GOV.UK Sign On <noreply-signon@digital.cabinet-office.gov.uk>"

  def suspension_reminder(user, days)
    @user, @days = user, days
    mail(to: @user.email, subject: suspension_reminder_subject)
  end

  def suspension_notification(user)
    @user = user
    mail(to: @user.email, subject: suspension_notification_subject)
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

  def app_name
    if instance_name.present?
      "GOV.UK Signon #{instance_name}"
    else
      "GOV.UK Signon"
    end
  end

  def account_name
    if instance_name.present?
      "#{instance_name} account"
    else
      "account"
    end
  end

  def instance_name
    Rails.application.config.instance_name
  end
end
