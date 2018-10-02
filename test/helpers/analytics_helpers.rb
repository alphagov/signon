module AnalyticsHelpers
  # GA is noisy in tests becayse all GA calls become console.log so we
  # don't want it enabled for all tests, use this to selectively turn it on
  def with_ga_enabled
    begin
      GovukAdminTemplate.configure { |c| c.enable_google_analytics_in_tests = true }
      yield
    ensure
      GovukAdminTemplate.configure { |c| c.enable_google_analytics_in_tests = false }
    end
  end

  def refute_dimension_is_set(dimension)
    refute_match(/#{Regexp.escape("GOVUKAdmin.setDimension(#{dimension}")}/, page.body)
  end

  def assert_dimension_is_set(dimension, with_value: nil)
    dimension_set_js_code = "ga('set', 'dimension#{dimension}"
    dimension_set_js_code += "', \"#{with_value}\")" if with_value.present?
    assert_match(/#{Regexp.escape(dimension_set_js_code)}/, page.body)
  end
end
