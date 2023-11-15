Rails.application.config.hosts << /signon(\..*gov.uk)?/

Rails.application.config.host_authorization = {
  exclude: ->(request) { request.path.include?("healthcheck") },
}