source 'https://rubygems.org'

#ruby=ruby-1.9.3
#ruby-gemset=quirkafleeg-signonotron2

gem 'rails', '3.2.13'

group :passenger_compatibility do
  gem 'rake', '0.9.2'
end

gem 'delayed_job', '3.0.5'
gem 'delayed_job_active_record', '0.4.4'
gem 'kaminari', '0.14.1'
gem 'paginate_alphabetically', '0.4.0', git: "https://github.com/edendevelopment/paginate_alphabetically.git", ref: "18d33ddc8bf93788bde80719fb63a5d345fda403"
gem 'mysql2'
gem 'aws-ses', require: 'aws/ses'
gem 'jquery-rails'
gem 'exception_notification'
gem 'plek', '1.4.0'
gem 'json', '1.7.7'

gem 'uuid'

gem 'dotenv-rails'

# Gems used to provide Authentication and Authorization services.
gem 'devise', '2.2.3'
gem 'devise_invitable', '1.1.5'
gem 'devise-encryptable', '0.1.1'
gem 'devise_security_extension', '0.7.2', git: "https://github.com/alphagov/devise_security_extension.git", branch: "graceful_return_to_behaviour"
gem 'passphrase_entropy', git: 'https://github.com/alphagov/passphrase_entropy.git'

gem 'doorkeeper', '0.6.7'

gem 'gds-api-adapters', '4.1.3'
gem 'statsd-ruby', '1.0.0'

group :development do
  gem 'sqlite3'
  gem 'quiet_assets'
end

gem 'lograge', '0.1.2'

group :test do
  gem 'cucumber-rails', '1.3.0', require: false
  gem 'database_cleaner', '0.7.2'
  gem 'factory_girl_rails', '3.1.0'
  gem 'mocha', '0.13.3', require: false
  gem 'shoulda', '3.0.1'
  gem 'webmock', '1.8.7'
  gem 'test-unit', '2.5.2', require: false
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'ci_reporter', '1.7.0'
end

group :production do
  gem 'foreman'
  gem 'thin'
end