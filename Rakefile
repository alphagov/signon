# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Signon::Application.load_tasks

begin
  require "pact/tasks"
rescue LoadError
  # Pact isn't available in all environments
end

Rake::Task[:default].clear_prerequisites
task default: %i[lint jasmine test]
