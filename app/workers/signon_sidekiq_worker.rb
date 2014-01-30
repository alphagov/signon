# exception notifications only after retries are exhausted
require 'extensions/sidekiq/exception_handler'

module SignonSidekiqWorker

  def self.included(base)
    base.class_eval do
      include Sidekiq::Worker
      sidekiq_options :retry => 6 # 6 retries over 4.5 mins
      sidekiq_retries_exhausted do |msg|
        Sidekiq.logger.warn "Failed to process #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
      end
    end
  end

end
