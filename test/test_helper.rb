if ENV["USE_SIMPLECOV"]
  require "simplecov"
end

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require 'rails/test_help'
require 'shoulda'
require "test/unit"
require "mocha/setup"
require 'webmock/test_unit'

WebMock.disable_net_connect!(:allow_localhost => true)

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  teardown do
    WebMock.reset!
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end

def with_const_override(const_sym, value)
  old_value = Object.send :remove_const, const_sym
  begin
    Object.send :const_set, const_sym, value
    yield
  ensure
    Object.send :remove_const, const_sym
    Object.send :const_set, const_sym, old_value
  end
end
