require "test_helper"

class UserAgentTest < ActiveSupport::TestCase
  setup do
    @user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
  end

  test "can create a valid record" do
    assert UserAgent.new(user_agent_string: @user_agent).valid?
  end

  test "requires an user agent" do
    assert_not UserAgent.new.valid?
  end
end
