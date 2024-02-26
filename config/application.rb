require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Signon
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_record.belongs_to_required_by_default = false

    config.active_record.encryption.key_derivation_salt = Rails.application.secrets.active_record_encryption[:key_derivation_salt]
    config.active_record.encryption.primary_key = Rails.application.secrets.active_record_encryption[:primary_key]

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading

    config.action_mailer.notify_settings = {
      api_key: Rails.application.secrets.notify_api_key || "fake-test-api-key",
    }

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "London"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.config.enforce_available_locales = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Prevent ActionDispatch::RemoteIp::IpSpoofAttackError when the client set a Client-IP
    # header and the request IP was interrogated.
    #
    # In our infrastructure, the protection this would give is provided by nginx, so
    # disabling it solves the above problem and doesn't give us additional risk.
    config.action_dispatch.ip_spoofing_check = false

    config.to_prepare do
      Doorkeeper::ApplicationController.layout "application"
    end

    config.eager_load_paths << Rails.root.join("lib")

    config.active_job.queue_adapter = :sidekiq

    config.action_dispatch.return_only_media_type_on_content_type = true

    # Set asset path to be application specific so that we can put all GOV.UK
    # assets into an S3 bucket and distinguish app by path.
    config.assets.prefix = "/assets/signon"

    # allows another asset host to be specified if different from app host
    config.asset_host = ENV.fetch("ASSET_HOST", nil)

    # Using a sass css compressor causes a scss file to be processed twice
    # (once to build, once to compress) which breaks the usage of "unquote"
    # to use CSS that has same function names as SCSS such as max.
    # https://github.com/alphagov/govuk-frontend/issues/1350
    config.assets.css_compressor = nil

    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.show_user_research_recruitment_banner = false

    config.add_autoload_paths_to_load_path = true
  end
end
