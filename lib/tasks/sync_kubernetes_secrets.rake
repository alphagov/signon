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

  desc "Synchronise OAuth App secrets in Kubernetes"
  task :sync_app_secrets, %i[config_map_name] => :environment do |_, args|
    client = Kubernetes::Client.new
    config_map = client.get_config_map(args[:config_map_name])

    app_names = JSON.parse(config_map.data["app_names"])
    apps = Doorkeeper::Application.where(name: app_names)

    missing_apps = app_names - apps.map(&:name)

    apps.each do |app|
      name = "signon-app-#{app.name}".parameterize
      data = { oauth_id: app.uid, oauth_secret: app.secret }

      client.apply_secret(name, data)
    end

    if missing_apps.any?
      raise StandardError, "Could not find apps for: #{missing_apps.join(', ')}"
    end
  end
end
