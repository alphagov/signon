class NoisyBatchInvitation < ActionMailer::Base
  default from: "ODI Sign On <noreply-signon@theodi.org>"
  default to: "signon-alerts@theodi.org"

  def make_noise(batch_invitation)
    @user = batch_invitation.user
    @batch_invitation = batch_invitation

    user_count = batch_invitation.batch_invitation_users.count
    subject = "[SIGNON] #{@user.name} created a batch of #{user_count} users"
    mail(subject: subject)
  end
end
