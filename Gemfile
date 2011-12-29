source 'http://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem 'rails', '3.1.3'

group :router do
  gem 'router-client', '2.0.3', :require => 'router/client'
end

# passenger compatability
group :passenger_compatibility do
  gem 'rack', '1.3.5'
  gem 'rake', '0.9.2'
end

gem 'json'
gem 'jquery-rails'

gem "ri_cal", "~> 0.8.8"
gem 'plek', '~> 0'
gem 'rummageable', :git => 'git@github.com:alphagov/rummageable.git'

if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', '~> 1.1'
end

if ENV['API_DEV']
  gem 'gds-api-adapters', :path => '../gds-api-adapters'
else
  gem 'gds-api-adapters', '~> 0.0.15'
end

group :test do
  gem 'factory_girl_rails'
  gem 'mocha', :require => false
  gem "shoulda", "~> 2.11.3"
  gem 'simplecov', '0.4.2'
  gem 'simplecov-rcov'
  gem 'webmock', :require => false
  gem 'ci_reporter'
  gem 'test-unit'
  # Pretty printed test output
  gem 'turn', :require => false
end

group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem "therubyracer", "~> 0.9.4"
  gem 'uglifier'
end
