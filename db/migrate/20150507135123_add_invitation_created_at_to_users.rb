class AddInvitationCreatedAtToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :invitation_created_at, :datetime
  end
end
