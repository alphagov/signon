class BulkGrantPermissionSet < ApplicationRecord
  belongs_to :user
  has_many :bulk_grant_permission_set_application_permissions, inverse_of: :bulk_grant_permission_set, dependent: :destroy
  has_many :supported_permissions, through: :bulk_grant_permission_set_application_permissions

  validates :user, presence: true
  validates :outcome, inclusion: { in: %w[success fail], allow_nil: true }
  validate :must_have_at_least_one_supported_permission

  def in_progress?
    outcome.nil?
  end

  def successful?
    outcome == "success"
  end

  def enqueue
    BulkGrantPermissionSetJob.perform_later(id)
  end

  def perform(_options = {})
    update_column(:total_users, User.count)
    User.find_each do |user_to_change|
      permissions_granted = supported_permissions.select do |permission|
        granted_permission = user_to_change.application_permissions.where(supported_permission_id: permission.id).first_or_create!
        # if 'id' changed then it was a new permission, otherwise it
        # already existed
        granted_permission.previous_changes.key? "id"
      end
      permissions_granted.group_by(&:application_id).each do |application_id, permissions|
        EventLog.record_event(
          user_to_change,
          EventLog::PERMISSIONS_ADDED,
          initiator: user,
          application_id: application_id,
          trailing_message: "(#{permissions.map(&:name).join(', ')})",
        )
      end
      self.class.increment_counter(:processed_users, id)
    end
    update_column(:outcome, "success")
  rescue StandardError
    update_column(:outcome, "fail")
    raise
  end

private

  def must_have_at_least_one_supported_permission
    errors.add(:supported_permissions, "must not be blank. Choose at least one permission to grant to all users.") if bulk_grant_permission_set_application_permissions.size.zero?
  end
end
