# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Signon::Application.load_tasks

require "sprockets/rails/task"
Sprockets::Rails::Task.new(Rails.application) do |t|
  t.log_level = Logger::WARN
end

Rake::Task[:default].clear_prerequisites
task default: %i[lint jasmine test]
