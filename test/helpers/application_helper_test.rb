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

  context "#with_checked_options_at_top" do
    should "put all checked options before all unchecked options" do
      options = [
        { label: "A", checked: false },
        { label: "B", checked: true },
        { label: "C", checked: false },
        { label: "D", checked: true },
      ]

      expected_options = [
        { label: "B", checked: true },
        { label: "D", checked: true },
        { label: "A", checked: false },
        { label: "C", checked: false },
      ]

      assert_equal expected_options, with_checked_options_at_top(options)
    end
  end

  test "#govuk_tag returns a strong tag with the given text, and the class govuk-tag" do
    assert_equal "<strong class=\"govuk-tag\">something</strong>", govuk_tag("something")
  end

  test "#govuk_tag returns a strong tag with the given text, and the classes govuk-tag plus any provided classes" do
    assert_equal "<strong class=\"govuk-tag some-class another--class\">something</strong>", govuk_tag("something", "some-class another--class")
  end
end
