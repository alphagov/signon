class UserMailer < ActionMailer::Base
  default from: "GOV.UK Sign On <noreply-signon@digital.cabinet-office.gov.uk>"

  def suspension_reminder(user, days)
    @user, @days = user, days
    mail(to: @user.email, subject: subject)
  end

private
  def subject
    "Your #{app_name} account will be suspended in #{@days} days"
  end

  def app_name
    instance_name = Rails.application.config.instance_name
    if instance_name.present?
      "GOV.UK Signon #{instance_name}"
    else
      "GOV.UK Signon"
    end
  end

end
