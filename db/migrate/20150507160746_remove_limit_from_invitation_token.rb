class RemoveLimitFromInvitationToken < ActiveRecord::Migration
  def up
    change_column :users, :invitation_token, :string, limit: nil
  end

  def down
    change_column :users, :invitation_token, :string, limit: 60
  end
end
