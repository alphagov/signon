source 'https://rubygems.org'

gem 'rails', '3.2.16'

group :passenger_compatibility do
  gem 'rake', '0.9.2'
end

gem 'delayed_job', '3.0.5'
gem 'delayed_job_active_record', '0.4.4'
gem 'kaminari', '0.14.1'
gem 'alphabetical_paginate', '2.1.0'
gem 'mysql2'
gem 'aws-ses', require: 'aws/ses'
gem 'jquery-rails'
gem 'exception_notification'
gem 'plek', '1.4.0'
gem 'json', '1.7.7'
gem 'whenever', '0.7.3', require: false

gem 'uuid'

# Gems used to provide Authentication and Authorization services.
gem 'devise', '2.2.5'
gem 'devise_invitable', '1.1.5'
gem 'devise-encryptable', '0.1.1'
gem 'devise_security_extension', '0.7.2', git: "https://github.com/alphagov/devise_security_extension.git", branch: "graceful_return_to_behaviour"
gem 'devise_zxcvbn', '1.0.0'

gem 'doorkeeper', '0.6.7'
gem 'ancestry', '2.0.0'
gem 'cancan', '1.6.10'

gem 'gds-api-adapters', '7.11.0'
gem 'statsd-ruby', '1.0.0'
gem 'unicorn', '4.3.1'
gem 'sidekiq', '2.17.2'

gem 'redis', '3.0.6'

group :development do
  gem 'sqlite3'
  gem 'quiet_assets'
end

gem 'logstasher', '0.4.1'

group :test do
  gem 'capybara', '2.2.1'
  gem 'database_cleaner', '0.7.2'
  gem 'factory_girl_rails', '4.3.0'
  gem 'mocha', '0.13.3', require: false
  gem 'shoulda', '3.0.1'
  gem 'webmock', '1.8.7'
  gem 'test-unit', '2.5.2', require: false
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'ci_reporter', '1.7.0'
end

