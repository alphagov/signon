class BatchInvitationJob
  include Sidekiq::Worker
  
  def perform(id,options = {})
    BatchInvitation.find(id).perform(options)
  end
end