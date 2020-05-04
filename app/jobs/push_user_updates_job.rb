class PushUserUpdatesJob < ApplicationJob
  include ActiveJob::Retry.new(strategy: :exponential, limit: 6)

  def perform(*_args)
    raise NotImplementedError, "PushUserUpdatesJob must be subclassed"
  end

  class << self
    def perform_on(user)
      user.applications_used.select(&:supports_push_updates?)
        .each { |application| perform_later(user.uid, application.id) }
    end
  end
end
