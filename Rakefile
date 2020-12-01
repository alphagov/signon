# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

require_relative "lib/volatile_lock"
include VolatileLock::DSL

Signon::Application.load_tasks

task default: %i[lint test jasmine:ci]
