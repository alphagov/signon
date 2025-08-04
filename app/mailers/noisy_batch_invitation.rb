class NoisyBatchInvitation < ApplicationMailer
  include MailerHelper

  default from: proc { email_from }
  default to: I18n.t("noisy_batch_invitation_mailer.to")

  def make_noise(batch_invitation)
    @user = batch_invitation.user
    @batch_invitation = batch_invitation

    user_count = batch_invitation.batch_invitation_users.count
    subject = "[SIGNON] #{@user.name} created a batch of #{user_count} users"
    subject << " in #{GovukEnvironment.current}" unless GovukEnvironment.current == "production"
    view_mail(template_id, to: I18n.t("noisy_batch_invitation_mailer.to"), subject:)
  end
end
