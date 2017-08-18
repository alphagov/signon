class BulkGrantPermissionSet < ActiveRecord::Base
  belongs_to :user
  has_many :bulk_grant_permission_set_application_permissions, inverse_of: :bulk_grant_permission_set, dependent: :destroy
  has_many :supported_permissions, through: :bulk_grant_permission_set_application_permissions

  validates :user, presence: true
  validates :outcome, inclusion: { in: %w(success fail), allow_nil: true }
  validate :must_have_at_least_one_supported_permission

  def in_progress?
    outcome.nil?
  end

  def successful?
    outcome == 'success'
  end

  def enqueue
    BulkGrantPermissionSetJob.perform_later(self.id)
  end

  def perform(_options = {})
    self.update_column(:total_users, User.count)
    User.find_each do |user|
      supported_permissions.each do |permission|
        user.application_permissions.where(supported_permission_id: permission.id).first_or_create!
      end
      self.class.increment_counter(:processed_users, self.id)
    end
    self.update_column(:outcome, "success")
  rescue StandardError
    self.update_column(:outcome, "fail")
    raise
  end

private

  def must_have_at_least_one_supported_permission
    errors.add(:supported_permissions, 'must not be blank. Choose at least one permission to grant to all users.') if bulk_grant_permission_set_application_permissions.size.zero?
  end
end
