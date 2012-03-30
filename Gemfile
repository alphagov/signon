source 'https://rubygems.org'

gem 'rails', '3.2.3'
gem 'mysql2'
gem 'aws-ses', require: 'aws/ses'
gem 'jquery-rails'

gem 'slimmer', :git => "git://github.com/alphagov/slimmer.git"
gem 'plek'

# Gems used to provide Authentication and Authorization services.
gem 'devise'
gem 'passphrase_entropy', :git => "git://github.com/alphagov/passphrase_entropy.git"

gem 'doorkeeper'

group :development do
  gem 'sqlite3'
end

group :test do
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'factory_girl_rails'
end

