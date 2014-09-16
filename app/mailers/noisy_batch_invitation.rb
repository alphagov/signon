class NoisyBatchInvitation < ActionMailer::Base
  default from: "GOV.UK Signon <noreply-signon@digital.cabinet-office.gov.uk>"
  default to: "signon-alerts@digital.cabinet-office.gov.uk"

  def make_noise(batch_invitation)
    @user = batch_invitation.user
    @batch_invitation = batch_invitation

    user_count = batch_invitation.batch_invitation_users.count
    subject = "[SIGNON] #{@user.name} created a batch of #{user_count} users"
    mail(subject: subject)
  end
end
