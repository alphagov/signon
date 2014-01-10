require 'redis_client'

class VolatileLock

  # expiration_time takes care of time-drifts on our
  # servers. defaults to 10.minutes assuming our servers
  # won't realistically have a greater time-drift.
  def initialize(key, expiration_time = 10.minutes)
    @key = key
    @expiration_time = expiration_time
  end

  def obtained?
    result = redis.setnx(@key, Socket.gethostname)
    redis.expire(@key, @expiration_time) if result
    result
  end

  def redis
    RedisClient.instance.connection
  end

end
