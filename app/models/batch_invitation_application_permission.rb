class BatchInvitationApplicationPermission < ApplicationRecord
  belongs_to :batch_invitation, inverse_of: :batch_invitation_application_permissions
  belongs_to :supported_permission

  validates :batch_invitation, :supported_permission, presence: true
  validates :supported_permission_id, uniqueness: { scope: :batch_invitation_id, case_sensitive: true }
end
