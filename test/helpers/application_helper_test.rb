require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "#sensitive_query_parameters? returns false when no parameters in the URL" do
    self.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/nothing-to-hide"))
    assert_not sensitive_query_parameters?
  end

  test "#sensitive_query_parameters? returns false when no sensitive parameters in the URL" do
    self.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/nothing-to-hide?share=witheveryone"))
    assert_not sensitive_query_parameters?
  end

  test "#sensitive_query_parameters? returns true when there is a reset_password_token in the URL" do
    self.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/secret-squirrel?reset_password_token=d1"))
    assert sensitive_query_parameters?
  end

  test "#sensitive_query_parameters? returns true when there is a invitation_token in the URL" do
    self.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/secret-squirrel?invitation_token=w1"))
    assert sensitive_query_parameters?
  end

  test "#sanitised_fullpath returns the URL without the sensitive query parameters" do
    self.request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/secret-squirrel?invitation_token=w1&reset_password_token=d1&sharing=ok"))
    assert_equal "/secret-squirrel?sharing=ok", sanitised_fullpath
  end
end
