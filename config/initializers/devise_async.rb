Devise::Async.setup do |config|
  config.enabled = Rails.env.production?
  config.backend = :sidekiq
end

class Devise::Async::Backend::Sidekiq
  sidekiq_options :retry => 5
  sidekiq_retry_in do |retry_count|
    # 15s, 1m, 12m, 1h8m, 4h20m
    (retry_count ** 6) + 15
  end
  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end
end
