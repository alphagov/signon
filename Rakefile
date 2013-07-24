#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Signonotron2::Application.load_tasks

Rake.application['default'].prerequisites.delete('cucumber') if Rake.application['default']
task :default => [:test, :check_for_bad_time_handling]
