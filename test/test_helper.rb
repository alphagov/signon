ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'simplecov'
require 'simplecov-rcov'
SimpleCov.start 'rails'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
