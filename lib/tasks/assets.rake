require "sprockets/rails/task"
Sprockets::Rails::Task.new(Rails.application) do |t|
  t.log_level = Logger::WARN
end

Rake::Task["assets:precompile"].enhance(["dartsass:build"])
