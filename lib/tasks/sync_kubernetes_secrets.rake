namespace :kubernetes do
  desc "Synchronise OAuth Token secrets in Kubernetes"
  task :sync_token_secrets, %i[config_map_name] => :environment do |_, args|
    client = Kubernetes::Client.new
    config_map = client.get_config_map(args[:config_map_name])

    emails = JSON.parse(config_map.data["api_user_emails"])

    api_users = ApiUser.where(email: emails)
    missing_users = emails - api_users.map(&:email)

    api_users.each do |api_user|
      api_user.authorisations.each do |token|
        name = "signon-token-#{api_user.name}-#{token.application.name}".parameterize
        data = { bearer_token: token.token }

        client.apply_secret(name, data)
      end
    end

    if missing_users.any?
      raise StandardError, "Could not find api users for: #{missing_users.join(', ')}"
    end
  end
end
