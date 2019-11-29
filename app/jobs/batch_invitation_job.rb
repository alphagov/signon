class BatchInvitationJob < ApplicationJob
  def perform(id, options = {})
    BatchInvitation.find(id).perform(options)
  end
end
