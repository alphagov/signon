require 'test_helper'

class VolatileLockTest < ActiveSupport::TestCase

  def teardown
    redis.del('test', 'foo', 'bar')
  end

  def redis
    RedisClient.instance.connection
  end

  def volatile_lock(key, expiration_time = 1.second)
    VolatileLock.new(key, expiration_time)
  end

  test "ensures only one lock is obtained per key" do
    assert_true volatile_lock('test').obtained?
    assert_false volatile_lock('test').obtained?
  end

  test "allows multiple locks to be obtaned if keys differ" do
    assert_true volatile_lock('foo').obtained?
    assert_true volatile_lock('bar').obtained?
  end

  test "allows expiration_time to be changed" do
    redis = mock(setnx: true)
    redis.expects(:expire).with('foo', 30.seconds)
    VolatileLock.any_instance.stubs(:redis).returns(redis)

    volatile_lock('foo', 30.seconds).obtained?
  end

end
