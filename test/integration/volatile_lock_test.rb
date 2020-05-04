require "test_helper"

class VolatileLockTest < ActiveSupport::TestCase
  def teardown
    redis.del("foo", "bar")
  end

  def redis
    RedisClient.instance.connection
  end

  def volatile_lock(key, expiration_time = 1.second)
    VolatileLock.new(key, expiration_time)
  end

  test "starts by deleting possibly stale locks created by the same host" do
    redis.set("foo", Socket.gethostname)
    assert volatile_lock("foo").obtained?
  end

  test "ensures only one lock is obtained per key across hosts" do
    Socket.stubs(:gethostname).returns("pluto")
    assert volatile_lock("foo").obtained?

    Socket.stubs(:gethostname).returns("mars")
    assert_not volatile_lock("foo").obtained?
  end

  test "allows multiple locks to be obtained if keys differ" do
    assert volatile_lock("foo").obtained?
    assert volatile_lock("bar").obtained?
  end

  test "allows expiration_time to be changed" do
    redis = mock(get: nil, setnx: true)
    redis.expects(:expire).with("foo", 30.seconds).returns(true)
    VolatileLock.any_instance.stubs(:redis).returns(redis)

    volatile_lock("foo", 30.seconds).obtained?
  end

  context "failing to set expiration time" do
    should "raise FailedToSetExpiration" do
      redis = mock(get: nil, setnx: true, del: true, expire: false)
      VolatileLock.any_instance.stubs(:redis).returns(redis)

      assert_raises(VolatileLock::FailedToSetExpiration) { volatile_lock("foo").obtained? }
    end

    should "delete the persisted key" do
      redis = mock(get: nil, setnx: true, expire: false)
      redis.expects(:del).with("foo")
      VolatileLock.any_instance.stubs(:redis).returns(redis)

      begin
        volatile_lock("foo").obtained?
      rescue StandardError
        VolatileLock::FailedToSetExpiration
      end
    end
  end
end
