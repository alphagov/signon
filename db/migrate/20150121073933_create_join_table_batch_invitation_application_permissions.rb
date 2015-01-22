class CreateJoinTableBatchInvitationApplicationPermissions < ActiveRecord::Migration
  def change
    create_table :batch_invitation_application_permissions do |t|
      t.integer :batch_invitation_id, null: false
      t.integer :supported_permission_id, null: false
      t.timestamps
    end

    add_index :batch_invitation_application_permissions, [:batch_invitation_id, :supported_permission_id], unique: true
  end
end
