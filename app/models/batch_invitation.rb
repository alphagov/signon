class BatchInvitation < ActiveRecord::Base
  belongs_to :user
  has_many :batch_invitation_users

  serialize :applications_and_permissions, Hash

  validates :outcome, inclusion: { :in => [nil, "success", "fail"] }
  validates :user_id, presence: true

  def in_progress?
    outcome.nil?
  end

  class Job < Struct.new(:id)
    def perform(options = {})
    end
  end
end
