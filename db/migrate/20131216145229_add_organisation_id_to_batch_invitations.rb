class AddOrganisationIdToBatchInvitations < ActiveRecord::Migration[6.0]
  def change
    add_column :batch_invitations, :organisation_id, :integer
  end
end
