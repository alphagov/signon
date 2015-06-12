source 'https://rubygems.org'

gem 'rails', '4.0.13'

gem 'kaminari', '0.16.1'
gem 'bootstrap-kaminari-views', '0.0.5'
gem 'alphabetical_paginate', '2.2.3'
gem 'mysql2'
gem 'govuk_admin_template', '1.4.2'

gem 'airbrake', '3.1.15'
gem 'plek', '1.7.0'
gem 'json', '1.8.0'
gem 'whenever', '~> 0.9.4', require: false

gem 'uuid'

# Gems used to provide Authentication and Authorization services.
gem 'devise', '3.2.2'
gem 'devise_invitable', '1.4.0'
gem 'devise-encryptable', '0.1.1'
gem 'devise_security_extension', '0.8.2', git: "https://github.com/alphagov/devise_security_extension.git", branch: "upstream-with-our-stuff"
gem 'devise_zxcvbn', '1.1.1'
gem 'devise-async', '0.9.0'
gem 'pundit', '0.3.0'

gem 'doorkeeper', '2.2.1'
gem 'ancestry', '2.0.0'

gem 'gds-api-adapters', '18.4.0'
gem 'statsd-ruby', '1.1.0'
gem 'unicorn', '4.3.1'
gem 'sidekiq', '2.17.2'
gem 'sidekiq-statsd', '0.1.2'

gem 'redis', '3.0.6'

gem 'zeroclipboard-rails'

gem 'rake', '10.4.1'

gem 'sass-rails', '4.0.3'

gem 'uglifier', '2.7.1'

group :development do
  gem 'quiet_assets', '1.0.2'
  # SQLite is needed only for signon to be run as part of gds-sso's test suite
  gem 'sqlite3'
end

group :development, :test do
  gem 'jasmine', '2.1.0'
end

gem 'logstasher', '0.4.8'

group :test do
  gem 'rspec-rails', '~> 3.1.0'
  gem 'capybara', '2.2.1'
  gem 'capybara-email', '~> 2.3.0'
  gem 'poltergeist', '1.5.0'
  gem 'database_cleaner', '1.4.1'
  gem 'factory_girl_rails', '4.3.0'
  gem 'mocha', '1.1.0', require: false
  gem 'webmock', '1.17.3'
  gem 'minitest', '4.7.5'
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'ci_reporter', '1.7.0'
  gem 'timecop', '0.7.1'
  gem 'shoulda-context', '1.2.1', require: false
  gem 'pry-byebug'
end
