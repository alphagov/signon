class AddBatchInvitation < ActiveRecord::Migration
  def up
    create_table :batch_invitations, force: true do |table|
      table.text :applications_and_permissions
      table.string :outcome # nil, "success", "fail", "skipped"
      table.timestamps
    end

    create_table :batch_invitation_users, force: true do |table|
      table.belongs_to :batch_invitation
      table.string :name
      table.string :email
      table.string :outcome # nil, "success", "fail", "skipped"
      table.timestamps
    end

    add_index :batch_invitation_users, :batch_invitation_id
    add_index :batch_invitations, :outcome
  end

  def down
    drop_table :batch_invitation_users
    drop_table :batch_invitations
  end
end
