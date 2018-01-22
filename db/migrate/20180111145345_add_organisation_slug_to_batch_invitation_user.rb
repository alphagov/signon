class AddOrganisationSlugToBatchInvitationUser < ActiveRecord::Migration[5.1]
  def change
    change_table :batch_invitation_users do |t|
      t.string :organisation_slug, null: true
    end
  end
end
