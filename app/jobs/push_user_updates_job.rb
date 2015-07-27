class PushUserUpdatesJob < ActiveJob::Base
  include ActiveJob::Retry

  exponential_retry limit: 6

  class << self
    def perform_on(user)
      user.applications_used.select(&:supports_push_updates?)
        .each { |application| self.perform_later(user.uid, application.id) }
    end
  end
end
