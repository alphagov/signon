class BatchInvitationApplicationPermission < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :batch_invitation
  belongs_to :supported_permission

  validates_presence_of :batch_invitation_id, :supported_permission_id
  validates_uniqueness_of :supported_permission_id, scope: :batch_invitation_id
end
