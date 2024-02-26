class BatchInvitation < ApplicationRecord
  belongs_to :user
  belongs_to :organisation
  has_many :batch_invitation_users, -> { order(:name) }
  has_many :batch_invitation_application_permissions, inverse_of: :batch_invitation
  has_many :supported_permissions, through: :batch_invitation_application_permissions

  serialize :applications_and_permissions, Hash, coder: YAML

  attr_accessor :user_names_and_emails

  validates :outcome, inclusion: { in: [nil, "success", "fail"] }
  validates :user_id, presence: true

  def has_permissions?
    batch_invitation_application_permissions.exists?
  end

  def in_progress?
    outcome.nil? && has_permissions?
  end

  def all_successful?
    !outcome.nil? && batch_invitation_users.failed.count.zero?
  end

  def enqueue
    NoisyBatchInvitation.make_noise(self).deliver_later
    BatchInvitationJob.perform_later(id)
  end

  def perform(_options = {})
    batch_invitation_users.unprocessed.each do |bi_user|
      bi_user.invite(user, supported_permission_ids)
    end
    self.outcome = "success"
    save!
  rescue StandardError
    update_column(:outcome, "fail")
    raise
  end

  def grant_permission(supported_permission)
    supported_permissions << supported_permission unless supported_permissions.include?(supported_permission)
  end
end
