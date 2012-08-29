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
gem 'passphrase_entropy', git: "https://github.com/alphagov/passphrase_entropy.git"

gem 'doorkeeper', '0.3.1'

gem "gds-api-adapters", "0.2.1"

group :development do
  gem 'sqlite3'
end

gem 'lograge'

group :test do
  gem 'cucumber-rails', require: false
  gem 'capybara', '1.1.2'
  gem 'database_cleaner'
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'factory_girl', "3.3.0"
  gem 'factory_girl_rails'
  gem 'ci_reporter', '1.7.1'
  gem 'minitest', '3.3.0'
  gem 'launchy'
  gem 'mocha', '0.12.3', require: false
  gem 'shoulda'
  gem 'webmock', '1.8.7', require: false
end

