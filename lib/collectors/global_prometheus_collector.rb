require "prometheus_exporter"
require "prometheus_exporter/server"

# Load Rails models as not automatically included for Prometheus Exporter
require File.expand_path("../../config/environment", __dir__) unless defined? Rails

module Collectors
  class GlobalPrometheusCollector < PrometheusExporter::Server::TypeCollector
    def type
      "signon_global"
    end

    def metrics
      token_expiry_timestamp = PrometheusExporter::Metric::Gauge.new("signon_api_user_token_expiry_timestamp_seconds", "Timestamp when API User token expires")

      token_expiry_info.each do |token|
        token_expiry_timestamp.observe(token[:expires_at], api_user: token[:api_user], application: token[:application_name])
      end

      [token_expiry_timestamp]
    end

  private

    def token_expiry_info
      # Cache metric to prevent needless expensive calls to the database
      Rails.cache.fetch("token_expiry_info", expires_in: 1.hour) do
        ApiUser.all.flat_map do |user|
          user.authorisations.not_revoked.map do |token|
            {
              expires_at: token.expires_at.to_i,
              api_user: user.email,
              application_name: token.application.name.parameterize,
            }
          end
        end
      end
    end
  end
end
