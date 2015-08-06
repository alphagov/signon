class NoisyBatchInvitation < ActionMailer::Base
  include MailerHelper

  default from: Proc.new { email_from }
  default to: "signon-alerts@digital.cabinet-office.gov.uk"

  def make_noise(batch_invitation)
    @user = batch_invitation.user
    @batch_invitation = batch_invitation

    user_count = batch_invitation.batch_invitation_users.count
    subject = "[SIGNON] #{@user.name} created a batch of #{user_count} users"
    subject << " in #{instance_name}" if instance_name
    mail(subject: subject)
  end
end
