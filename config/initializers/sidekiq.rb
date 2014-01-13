Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'signon' }
end
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'signon' }
end