require "redis_client"

class VolatileLock
  class FailedToSetExpiration < StandardError; end

  module DSL
    def with_lock(key)
      # lock for next 10.minutes
      if VolatileLock.new(key).obtained?
        yield
      else
        puts "Skipping task on #{Socket.gethostname}, couldn't obtain lock: #{key}"
      end
    end
  end

  # expiration_time takes care of time-drifts on our
  # servers. defaults to 10.minutes assuming our servers
  # won't realistically have a greater time-drift.
  def initialize(key, expiration_time = 10.minutes)
    @key = key
    @expiration_time = expiration_time
  end

  def obtained?
    delete_possibly_stale_keys

    result = redis.setnx(@key, hostname)
    result = expire if result
    result
  end

private

  def expire
    result = redis.expire(@key, @expiration_time)
    return true if result

    redis.del(@key)
    raise FailedToSetExpiration
  end

  def delete_possibly_stale_keys
    redis.del(@key) if redis.get(@key) == hostname
  end

  def redis
    RedisClient.instance.connection
  end

  def hostname
    Socket.gethostname
  end
end
