# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Signon::Application.load_tasks

begin
  require "pact/tasks"
rescue LoadError
  # Pact isn't available in all environments
end

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:pact_verify_v2) do |task|
    task.pattern = "spec/pact/consumers/**/*_spec.rb"
    task.rspec_opts = "--require rails_helper --tag pact_v2"
  end

  namespace :pact do
    desc "Pact v2 verification"
    task verify_v2: :pact_verify_v2
  end
rescue LoadError
  # Pact isn't available in all environments
end

Rake::Task[:default].clear_prerequisites
task default: %i[lint jasmine test]
