class UserApplicationPermission < ApplicationRecord
  belongs_to :user
  belongs_to :application, class_name: "Doorkeeper::Application"
  belongs_to :supported_permission

  validates :user, :supported_permission, :application, presence: true
  validates :supported_permission_id, uniqueness: { scope: %i[user_id application_id], case_sensitive: true }

  before_validation :assign_application_id

private

  # application_id is duplicated across supported_permissions and user_application_permissions
  # to efficiently address common queries for a user's permissions for a particular application
  def assign_application_id
    self.application_id = supported_permission.application_id if supported_permission.present?
  end
end
