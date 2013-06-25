class BatchInvitation < ActiveRecord::Base
  belongs_to :user
  has_many :batch_invitation_users

  serialize :applications_and_permissions, Hash

  validates :outcome, inclusion: { :in => [nil, "success", "fail"] }
  validates :user_id, presence: true

  def in_progress?
    outcome.nil?
  end

  def all_successful?
    batch_invitation_users.failed.count == 0
  end

  def enqueue
    NoisyBatchInvitation.make_noise(self).deliver
    Delayed::Job.enqueue(BatchInvitation::Job.new(self.id))
  end

  def perform(options = {})
    self.batch_invitation_users.each do |bi_user|
      bi_user.invite(self.user, self.applications_and_permissions)
    end
    self.outcome = "success"
    self.save!
  rescue StandardError => e
    self.update_column(:outcome, "fail")
    raise
  end

  class Job < Struct.new(:id)
    def perform(options = {})
      BatchInvitation.find(id).perform(options)
    end
  end
end
