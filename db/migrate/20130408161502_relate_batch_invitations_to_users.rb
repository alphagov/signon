class RelateBatchInvitationsToUsers < ActiveRecord::Migration[4.2][4.2]
  def up
    add_column :batch_invitations, :user_id, :integer, null: false
  end

  def down
    remove_column :batch_invitations, :user_id
  end
end
