class BatchInvitationApplicationPermission < ActiveRecord::Base
  belongs_to :batch_invitation, inverse_of: :batch_invitation_application_permissions
  belongs_to :supported_permission

  validates_presence_of :batch_invitation, :supported_permission
  validates_uniqueness_of :supported_permission_id, scope: :batch_invitation_id
end
