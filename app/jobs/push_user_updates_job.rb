class PushUserUpdatesJob < ActiveJob::Base
  include ActiveJob::Retry

  def self.inherited(subclass)
    subclass.exponential_retry limit: 6
  end

  def perform(*args)
    raise NotImplementedError, "PushUserUpdatesJob must be subclassed"
  end

  class << self
    def perform_on(user)
      user.applications_used.select(&:supports_push_updates?)
        .each { |application| self.perform_later(user.uid, application.id) }
    end
  end
end
