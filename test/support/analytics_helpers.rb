module AnalyticsHelpers
  # GA is noisy in tests becayse all GA calls become console.log so we
  # don't want it enabled for all tests, use this to selectively turn it on
  def with_ga_enabled
    GovukAdminTemplate.configure { |c| c.enable_google_analytics_in_tests = true }
    yield
  ensure
    GovukAdminTemplate.configure { |c| c.enable_google_analytics_in_tests = false }
  end

  def refute_dimension_is_set(dimension)
    js_code = dimension_set_js_code(dimension)
    assert_not page.has_text?(:all, js_code)
  end

  def assert_dimension_is_set(dimension, with_value: nil)
    js_code = dimension_set_js_code(dimension, with_value:)
    assert page.has_text?(:all, js_code)
  end

private

  def dimension_set_js_code(dimension, with_value: nil)
    code = "ga('set', 'dimension#{dimension}"
    with_value.present? ? code + "', \"#{with_value}\")" : code
  end

  def google_analytics_page_view_path
    case page.body
    when Regexp.new("ga\\('send', 'pageview', { page: '(?<explicit_path>[^']*)' }\\)")
      Regexp.last_match[:explicit_path]
    when Regexp.new("ga\\('send', 'pageview'\\)")
      page.current_path
    else
      flunk "Google Analytics page view not sent"
    end
  end
end
