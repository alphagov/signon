require "sprockets/rails/task"
Sprockets::Rails::Task.new(Rails.application) do |t|
  t.log_level = Logger::WARN
end
