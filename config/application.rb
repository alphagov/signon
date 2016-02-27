require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Signonotron2
  def self.mysql?
    ENV.fetch("SIGNONOTRON2_DB_ADAPTER", "mysql") == "mysql"
  end

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'London'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.config.enforce_available_locales = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    # Note: filter_parameters are treated as regexes, so :password also matches
    # current_password, password_confirmation and password-strength-score
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.version = '1.0'

    #config.middleware.insert_before Warden::Manager, Slimmer::App, config.slimmer.to_hash

    # Prevent ActionDispatch::RemoteIp::IpSpoofAttackError when the client set a Client-IP
    # header and the request IP was interrogated.
    #
    # In our infrastructure, the protection this would give is provided by nginx, so
    # disabling it solves the above problem and doesn't give us additional risk.
    config.action_dispatch.ip_spoofing_check = false

    # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
    config.assets.precompile += %w(password-strength-indicator.js)

    config.to_prepare do
      Doorkeeper::ApplicationController.layout "application"
    end

    config.autoload_paths << Rails.root.join('lib')

    config.active_job.queue_adapter = :sidekiq
  end
end
