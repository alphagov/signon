class StripWhitespaceFromBatchInvitationUserOrganisationSlug < ActiveRecord::Migration[7.0]
  def change
    BatchInvitationUser.where("organisation_slug REGEXP ? OR organisation_slug REGEXP ?", "^\\s+", "\\s+$").each do |biu|
      biu.update_attribute(:organisation_slug, biu.organisation_slug&.strip) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
