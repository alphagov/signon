class BatchInvitation < ActiveRecord::Base
  belongs_to :user
  has_many :batch_invitation_users

  serialize :applications_and_permissions, Hash

  validates :outcome, inclusion: { :in => [nil, "success", "fail"] }
  validates :user_id, presence: true

  def in_progress?
    outcome.nil?
  end

  def perform(options = {})
    self.batch_invitation_users.each do |bi_user|
      attributes = {
        name: bi_user.name,
        email: bi_user.email,
        permissions_attributes: self.applications_and_permissions
      }
      begin
        User.invite!(attributes, self.user)
      rescue StandardError => e
      end
    end
    self.outcome = "success"
    self.save!
  end

  class Job < Struct.new(:id)
    def perform(options = {})
      BatchInvitation.find(id).perform(options)
    end
  end
end
