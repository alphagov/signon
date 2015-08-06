# This file is overwritten on deploy

Sidekiq.configure_client do |config|
  config.redis = { namespace: 'signon' }
end
Sidekiq.configure_server do |config|
  config.redis = { namespace: 'signon' }
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::RetryJobs, max_retries: 5
  end
end
