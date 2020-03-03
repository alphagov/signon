class BulkGrantPermissionSetApplicationPermission < ApplicationRecord
  belongs_to :bulk_grant_permission_set, inverse_of: :bulk_grant_permission_set_application_permissions
  belongs_to :supported_permission

  validates :bulk_grant_permission_set, :supported_permission, presence: true
  validates :supported_permission_id, uniqueness: { scope: :bulk_grant_permission_set_id, case_sensitive: true }
end
