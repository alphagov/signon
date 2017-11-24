class AddOrganisationIdToBatchInvitations < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :batch_invitations, :organisation_id, :integer
  end
end
