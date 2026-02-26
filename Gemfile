source "https://rubygems.org"

gem "rails", "8.0.4"

gem "activejob-retry"
gem "addressable"
gem "ancestry"
gem "bootsnap", require: false
gem "browser"
gem "csv"
gem "dartsass-rails"
gem "devise"
gem "devise-encryptable"
gem "devise_invitable"
gem "devise_zxcvbn", "~> 1.1"
gem "doorkeeper"
gem "json"
gem "kaminari"
gem "kubeclient"
gem "mail-notify"
gem "mysql2"
gem "nokogiri"
gem "pundit"
gem "rack-attack"
gem "rails-html-sanitizer"
gem "rake"
gem "redis"
gem "rotp"
gem "rqrcode"
gem "sentry-sidekiq"
gem "sprockets-rails"
gem "terser"
gem "uuid"

# GDS Gems
gem "gds-api-adapters"
gem "govuk_app_config"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "plek"

group :development do
  gem "better_errors"
  gem "binding_of_caller"
  gem "listen"
end

group :development, :test do
  gem "database_cleaner"
  gem "govuk_test"
  gem "pact", require: false
  gem "pact_broker-client"
  gem "pry-byebug"
  gem "rubocop-govuk"
end

group :test do
  gem "capybara"
  gem "capybara-email"
  gem "climate_control"
  gem "factory_bot_rails"
  gem "minitest", "< 6"
  gem "mocha", require: false
  gem "rails-controller-testing"
  gem "shoulda-context", require: false
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
