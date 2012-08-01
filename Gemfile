source 'https://rubygems.org'

gem 'rails', '3.1.3'

group :passenger_compatibility do
  gem 'rack', '1.3.5'
  gem 'rake', '0.9.2'
end

gem 'mysql2'
gem 'aws-ses', require: 'aws/ses'
gem 'jquery-rails'
gem 'aws-ses', :require => 'aws/ses' # Needed by exception_notification
gem 'exception_notification'

gem 'plek'

gem 'uuid'

# Gems used to provide Authentication and Authorization services.
gem 'devise'
gem 'devise_invitable'
gem 'passphrase_entropy', git: "git://github.com/alphagov/passphrase_entropy.git"

gem 'doorkeeper'

gem "gds-api-adapters", "0.2.1"

group :development do
  gem 'sqlite3'
end

gem 'lograge'

group :test do
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'mocha', '0.12.1', :require => false
  gem 'shoulda'
  gem 'webmock'
end

