class BatchInvitation < ActiveRecord::Base
  belongs_to :user
  belongs_to :organisation
  has_many :batch_invitation_users

  serialize :applications_and_permissions, Hash

  attr_accessor :user_names_and_emails

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
    Worker.perform_async(self.id)
  end

  def perform(options = {})
    self.batch_invitation_users.unprocessed.each do |bi_user|
      bi_user.invite(self.user, self.applications_and_permissions)
    end
    self.outcome = "success"
    self.save!
  rescue StandardError => e
    self.update_column(:outcome, "fail")
    raise
  end

  class Worker
    include Sidekiq::Worker
    def perform(id, options = {})
      BatchInvitation.find(id).perform(options)
    end
  end
end
