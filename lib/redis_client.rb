require "redis"

class RedisClient
  include Singleton

  attr_reader :connection

  def initialize
    @connection = Redis.new(config.symbolize_keys)
  end

private

  def config
    Rails.application.config_for(:redis)
  end
end
