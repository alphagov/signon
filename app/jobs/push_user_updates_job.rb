class PushUserUpdatesJob < ApplicationJob
  include ActiveJob::Retry.new(strategy: :exponential, limit: 6)

  def perform(*_args)
    raise NotImplementedError, "PushUserUpdatesJob must be subclassed"
  end

  class << self
    def perform_on(user)
      user.authorised_applications
        .each { |application| perform_later(user.uid, application.id) }
    end
  end
end
