class BatchInvitationUser < ApplicationRecord
  belongs_to :batch_invitation

  validates :email, presence: true, format: { with: Devise.email_regexp }

  validates :outcome, inclusion: { in: [nil, "success", "failed", "skipped"] }

  before_save :strip_whitespace_from_name

  scope :processed, -> { where.not(outcome: nil) }
  scope :unprocessed, -> { where(outcome: nil) }
  scope :failed, -> { where(outcome: "failed") }

  def invite(inviting_user, supported_permission_ids)
    sanitised_attributes = sanitise_attributes_for_inviting_user_role(
      {
        name:,
        email:,
        organisation_id:,
        supported_permission_ids:,
        require_2sv:,
      },
      inviting_user,
    )

    invite_user_with_attributes(sanitised_attributes, inviting_user)
  rescue InvalidOrganisationSlug => e
    update_column(:outcome, "failed")
    GovukError.notify(e)
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

  def organisation_id
    organisation_from_slug&.id || batch_invitation.organisation_id
  end

  def organisation_from_slug
    # allow memoizing nil with a defined? check instead of ||=
    if defined? @organisation_from_slug
      @organisation_from_slug
    elsif organisation_slug?
      org = Organisation.find_by(slug: organisation_slug)
      if org.nil?
        raise InvalidOrganisationSlug, organisation_slug
      else
        @organisation_from_slug = org
      end
    else
      @organisation_from_slug = nil
    end
  end

  def require_2sv
    Organisation.find(organisation_id).require_2sv?
  rescue ActiveRecord::RecordNotFound
    true
  end

  class InvalidOrganisationSlug < StandardError; end

private

  def invite_user_with_attributes(sanitised_attributes, inviting_user)
    if User.find_by(email:)
      update_column(:outcome, "skipped")
    else
      begin
        user = User.invite!(sanitised_attributes.to_h, inviting_user)
        if user.persisted?
          update_column(:outcome, "success")
        else
          update_column(:outcome, "failed")
          GovukError.notify("User not persisted", extra: sanitised_attributes.to_h)
        end
      rescue StandardError => e
        update_column(:outcome, "failed")
        GovukError.notify(e, extra: sanitised_attributes.to_h)
      end
    end
  end

  def sanitise_attributes_for_inviting_user_role(raw_attributes, inviting_user)
    UserParameterSanitiser.new(
      user_params: raw_attributes,
      current_user_role: inviting_user.role.to_sym,
    ).sanitise
  end

  def strip_whitespace_from_name
    name.strip!
  end
end
