class CreateJoinTableBatchInvitationApplicationPermissions < ActiveRecord::Migration
  def change
    create_table :batch_invitation_application_permissions do |t|
      t.integer :batch_invitation_id, null: false
      t.integer :supported_permission_id, null: false
      t.timestamps
    end
  end
end
