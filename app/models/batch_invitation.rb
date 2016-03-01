class BatchInvitation < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user
  belongs_to :organisation
  has_many :batch_invitation_users, -> { order(:name) }
  has_many :batch_invitation_application_permissions, inverse_of: :batch_invitation
  has_many :supported_permissions, through: :batch_invitation_application_permissions

  serialize :applications_and_permissions, Hash

  attr_accessor :user_names_and_emails

  validates :outcome, inclusion: { in: [nil, "success", "fail"] }
  validates :user_id, presence: true

  def in_progress?
    outcome.nil?
  end

  def all_successful?
    batch_invitation_users.failed.count == 0
  end

  def enqueue
    NoisyBatchInvitation.make_noise(self).deliver_later
    BatchInvitationJob.perform_later(self.id)
  end

  def perform(options = {})
    self.batch_invitation_users.unprocessed.each do |bi_user|
      bi_user.invite(user, supported_permission_ids)
    end
    self.outcome = "success"
    self.save!
  rescue StandardError => e
    self.update_column(:outcome, "fail")
    raise
  end
end
