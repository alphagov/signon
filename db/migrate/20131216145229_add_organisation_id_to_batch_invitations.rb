class AddOrganisationIdToBatchInvitations < ActiveRecord::Migration
  def change
    add_column :batch_invitations, :organisation_id, :integer
  end
end
