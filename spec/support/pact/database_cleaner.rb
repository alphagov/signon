require "database_cleaner/active_record"

if ENV["DATABASE_URL"]
  compose_file = Rails.root.join("../govuk-docker/projects/signon/docker-compose.yml")
  raise "Cannot build DatabaseCleaner allow list; #{compose_file} not found" unless compose_file.exist?

  compose_yaml = YAML.safe_load(File.read(compose_file), aliases: true)

  database_urls = compose_yaml.fetch("services", {}).flat_map { |_name, service|
    env = service["environment"] || {}
    env = env.map { |key, val| "#{key}=#{val}" } if env.is_a?(Hash) # could be hash or list
    env.grep(/\A(?:TEST_)?DATABASE_URL=/) { _1.split("=", 2).last }
  }.uniq

  DatabaseCleaner.url_allowlist = database_urls
end

DatabaseCleaner.strategy = :truncation
