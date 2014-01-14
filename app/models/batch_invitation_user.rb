class BatchInvitationUser < ActiveRecord::Base
  belongs_to :batch_invitation

  validates :outcome, inclusion: { :in => [nil, "success", "failed", "skipped"] }

  scope :processed, where("outcome IS NOT NULL")
  scope :unprocessed, where("outcome IS NULL")
  scope :failed, where(outcome: "failed")

  def invite(inviting_user, applications_and_permissions)
    attributes = {
      name: self.name,
      email: self.email,
      organisation_id: batch_invitation.organisation_id,
      permissions_attributes: applications_and_permissions
    }
    if User.find_by_email(self.email)
      self.update_column(:outcome, "skipped")
    else
      begin
        user = User.invite!(attributes, inviting_user)
        if user.persisted?
          self.update_column(:outcome, "success")
        else
          self.update_column(:outcome, "failed")
        end
      rescue StandardError => e
        self.update_column(:outcome, "failed")
      end
    end
  end

  def humanized_outcome
    if outcome == "skipped"
      "Skipped: user already existed."
    elsif outcome.present?
      outcome.capitalize
    else
      outcome
    end
  end
end
