ENV["RAILS_ENV"] = "test"
require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "shoulda/context"
require "webmock/minitest"
require "mocha/minitest"

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  teardown do
    Timecop.return
    WebMock.reset!
    Mail::TestMailer.deliveries.clear
  end
end

WebMock.disable_net_connect!(allow_localhost: true)

require "support/confirmation_token_helpers"

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ConfirmationTokenHelpers

  def sign_in(user)
    warden.stubs(authenticate!: user)
    @controller.stubs(current_user: user)
  end

  def sign_out(_user)
    warden.unstub(:authenticate!)
    @controller.unstub(:current_user)
  end
end

Capybara.server = :webrick

require "capybara/rails"

Capybara.register_driver :rack_test do |app|
  # capybara/rails sets up the rack-test driver to respect data-method attributes.
  # https://github.com/jnicklas/capybara/blob/2.2_stable/lib/capybara/rails.rb#L18-L20
  #
  # This is problematic because it's not a javascript driver, and therefore isn't running
  # the javascript that would use these, and insert the CSRF token.
  #
  # It's better to not respect these attributes in this driver, because it then behaves like
  # a normal browser with javascript disabled.
  Capybara::RackTest::Driver.new(app)
end

require "capybara/poltergeist"
Capybara.javascript_driver = :poltergeist

require "support/user_helpers"
require "support/email_helpers"
require "support/analytics_helpers"

class ActiveRecord::Base
  mattr_accessor :shared_connection

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include UserHelpers
  include EmailHelpers
  include ConfirmationTokenHelpers
  include AnalyticsHelpers

  def assert_response_contains(content)
    assert page.has_content?(content), "Expected to find '#{content}' in:\n#{page.text}"
  end

  def refute_response_contains(content)
    assert page.has_no_content?(content), "Expected not to find '#{content}' in:\n#{page.text}"
  end

  def assert_current_url(path_with_query, options = {})
    expected = URI.parse(path_with_query)
    current = URI.parse(current_url)
    assert_equal expected.path, current.path
    unless options[:ignore_query]
      assert_equal Rack::Utils.parse_query(expected.query), Rack::Utils.parse_query(current.query)
    end
  end

  def use_javascript_driver
    Capybara.current_driver = Capybara.javascript_driver
  end

  setup do
    # Enable CSRF protection in integration tests
    @original_forgery_protection_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
    ActionController::Base.allow_forgery_protection = @original_forgery_protection_value
  end
end
