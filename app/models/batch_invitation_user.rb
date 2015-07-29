class BatchInvitationUser < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :batch_invitation

  validates :outcome, inclusion: { in: [nil, "success", "failed", "skipped"] }

  scope :processed, -> { where.not(outcome: nil) }
  scope :unprocessed, -> { where(outcome: nil) }
  scope :failed, -> { where(outcome: "failed") }

  def invite(inviting_user, supported_permission_ids)
    sanitised_attributes = sanitise_attributes_for_inviting_user_role(
      {
        name: self.name,
        email: self.email,
        organisation_id: batch_invitation.organisation_id,
        supported_permission_ids: supported_permission_ids,
      },
      inviting_user,
    )

    invite_user_with_attributes(sanitised_attributes, inviting_user)
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

private
  def invite_user_with_attributes(sanitised_attributes, inviting_user)
    if User.find_by_email(self.email)
      self.update_column(:outcome, "skipped")
    else
      begin
        user = User.invite!(sanitised_attributes, inviting_user)
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

  def sanitise_attributes_for_inviting_user_role(raw_attributes, inviting_user)
    UserParameterSanitiser.new(
      user_params: raw_attributes,
      current_user_role: inviting_user.role.to_sym,
    ).sanitise
  end
end
