class BatchInvitationJob < ActiveJob::Base
  def perform(id, options = {})
    BatchInvitation.find(id).perform(options)
  end
end
