ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'simplecov'
require 'simplecov-rcov'
require 'slimmer/skin'
require 'slimmer/test'

SimpleCov.start 'rails'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

require 'webmock/test_unit'
WebMock.disable_net_connect!(:allow_localhost => true)
