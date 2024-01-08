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

    # Rotate SHA1 cookies to SHA256 (the new Rails 7 default)
    # TODO: Remove this after existing user sessions have been rotated
    # https://guides.rubyonrails.org/v7.0/upgrading_ruby_on_rails.html#key-generator-digest-class-changing-to-use-sha256
    config.action_dispatch.cookies_rotations.tap do |cookies|
      salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
      secret_key_base = Rails.application.secrets.secret_key_base
      next if secret_key_base.blank?

      key_generator = ActiveSupport::KeyGenerator.new(
        secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
      )
      key_len = ActiveSupport::MessageEncryptor.key_len
      secret = key_generator.generate_key(salt, key_len)

      cookies.rotate :encrypted, secret
    end

    config.show_user_research_recruitment_banner = false
  end
end
