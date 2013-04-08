class BatchInvitationUser < ActiveRecord::Base
  belongs_to :batch_invitation

  validates :outcome, inclusion: { :in => [nil, "success", "fail", "skipped"] }

  scope :processed, where("outcome IS NOT NULL")
end
