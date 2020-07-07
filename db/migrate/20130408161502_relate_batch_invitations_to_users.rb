class RelateBatchInvitationsToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :batch_invitations, :user_id, :integer, null: false
  end

  def down
    remove_column :batch_invitations, :user_id
  end
end
