# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Signon::Application.load_tasks

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:pact_verify) do |task|
    task.pattern = "spec/pact/consumers/**/*_spec.rb"
    task.rspec_opts = "--require rails_helper --tag pact"
  end

  namespace :pact do
    desc "Pact verification"
    task verify: :pact_verify
  end
rescue LoadError
  # Pact isn't available in all environments
end

Rake::Task[:default].clear_prerequisites
task default: %i[lint jasmine test pact:verify]
