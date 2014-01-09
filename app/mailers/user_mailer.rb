class UserMailer < ActionMailer::Base
  default from: "GOV.UK Sign On <noreply-signon@digital.cabinet-office.gov.uk>"

  def suspension_reminder(user, days)
    @user, @days = user, days
    mail(to: @user.email, subject: "Action required: your account will be suspended")
  end

end
