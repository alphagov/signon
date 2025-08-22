ENV["RAILS_ENV"] = "test"
ENV["GOVUK_ENVIRONMENT"] = "test"

require "simplecov"
SimpleCov.start "rails"

require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "shoulda/context"
require "webmock/minitest"
require "minitest/autorun"
require "mocha/minitest"

GovukTest.configure

Capybara.register_driver :headless_chrome do |app|
  chrome_options = GovukTest.headless_chrome_selenium_options
  chrome_options.add_argument("--no-sandbox")

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: chrome_options,
  )
end

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
require "support/pundit_helpers"

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ConfirmationTokenHelpers
  include PunditHelpers

  def sign_in(user, passed_mfa: true)
    warden.stubs(authenticate!: user)
    unless passed_mfa
      user.update!(otp_secret_key: ROTP::Base32.random_base32)
      warden.stubs(session: ->(_user) { { "need_two_step_verification" => true } })
      @controller.stubs(signed_in?: true)
    end
    @controller.stubs(current_user: user)
  end

  def sign_out(_user)
    warden.unstub(:authenticate!)
    warden.unstub(:session)
    @controller.unstub(:current_user)
  end

  def assert_not_authenticated
    assert_redirected_to new_user_session_path
  end

  def assert_not_authorised
    assert_redirected_to root_path
    assert_equal "You do not have permission to perform this action.", flash[:alert]
  end
end

# Capybara.server = :webrick
#
# require "capybara/rails"
#
# Capybara.register_driver :rack_test do |app|
#   # capybara/rails sets up the rack-test driver to respect data-method attributes.
#   # https://github.com/jnicklas/capybara/blob/2.2_stable/lib/capybara/rails.rb#L18-L20
#   #
#   # This is problematic because it's not a javascript driver, and therefore isn't running
#   # the javascript that would use these, and insert the CSRF token.
#   #
#   # It's better to not respect these attributes in this driver, because it then behaves like
#   # a normal browser with javascript disabled.
#   Capybara::RackTest::Driver.new(app)
# end
#
# require "capybara/poltergeist"
# Capybara.javascript_driver = :poltergeist

require "support/user_helpers"
require "support/email_helpers"
require "support/managing_two_sv_helpers"
require "support/user_account_helpers"
require "support/editing_users_helpers"
require "support/granting_access_helpers"
require "support/removing_access_helpers"
require "support/updating_permissions_helpers"
require "support/flash_helpers"
require "support/autocomplete_helper"

class ActiveRecord::Base
  mattr_accessor :shared_connection

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

require "capybara/rails"

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include UserHelpers
  include EmailHelpers
  include ConfirmationTokenHelpers
  include UserAccountHelpers
  include EditingUsersHelpers
  include GrantingAccessHelpers
  include RemovingAccessHelpers
  include UpdatingPermissionsHelpers
  include FlashHelpers

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
