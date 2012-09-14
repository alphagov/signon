source 'https://rubygems.org'

gem 'rails', '3.2.7'

group :passenger_compatibility do
  gem 'rake', '0.9.2'
end

gem 'mysql2'
gem 'aws-ses', require: 'aws/ses'
gem 'jquery-rails'
gem 'exception_notification'
gem 'plek'

gem 'uuid'

# Gems used to provide Authentication and Authorization services.
gem 'devise', '2.0.4'
gem 'devise_invitable', '1.0.2'
gem 'passphrase_entropy', git: 'https://github.com/alphagov/passphrase_entropy.git'

gem 'doorkeeper', '0.3.1'

gem 'gds-api-adapters', '0.2.1'
gem 'statsd-ruby', '1.0.0'
gem 'unicorn', '4.3.1'

group :development do
  gem 'sqlite3'
end

gem 'lograge'

group :test do
  gem 'cucumber-rails', '1.3.0', require: false
  gem 'database_cleaner', '0.7.2'
  gem 'factory_girl_rails', '3.1.0'
  gem 'mocha', '0.12.1', require: false
  gem 'shoulda', '3.0.1'
  gem 'webmock', '1.8.7'
  gem 'test-unit', '2.5.2', require: false
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'ci_reporter', '1.7.0'
end

