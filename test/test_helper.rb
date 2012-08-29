if ENV["USE_SIMPLECOV"]
  require "simplecov"
end

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require 'rails/test_help'
require 'shoulda'
require "mocha"
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all
  include MiniTest::Assertions
  # Add more helper methods to be used by all tests here...

  teardown do
    WebMock.reset!
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
end
