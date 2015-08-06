require 'redis'

class RedisClient
  include Singleton

  attr_reader :connection

  def initialize
    @connection = Redis.new(config.symbolize_keys)
  end

private

  def config
    YAML.load_file(Rails.root.join("config", "redis.yml"))
  end
end
