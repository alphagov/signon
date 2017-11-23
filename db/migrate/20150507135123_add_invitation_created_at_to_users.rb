class AddInvitationCreatedAtToUsers < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :users, :invitation_created_at, :datetime
  end
end
