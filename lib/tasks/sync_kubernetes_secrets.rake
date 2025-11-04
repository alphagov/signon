namespace :kubernetes do
  desc "Synchronise OAuth Token secrets in Kubernetes"
  task sync_token_secrets: :environment do
    client = Kubernetes::Client.new

    api_users = ApiUser.where(suspended_at: nil)

    api_users.each do |api_user|
      api_user.authorisations.not_revoked.ordered_by_expires_at.group_by(&:application).each do |application, authorisations|
        token_to_use = authorisations.last

        name = "signon-token-#{api_user.name}-#{application.name}".parameterize
        data = { bearer_token: token_to_use.token }

        Rails.logger.info(name)
        client.apply_secret(name, data)
      end
    end
  end

  desc "Synchronise OAuth App secrets in Kubernetes"
  task sync_app_secrets: :environment do
    client = Kubernetes::Client.new

    apps = Doorkeeper::Application.where(retired: false)

    apps.each do |app|
      name = "signon-app-#{app.name}".parameterize
      data = { oauth_id: app.uid, oauth_secret: app.secret }

      Rails.logger.info(name)
      client.apply_secret(name, data)
    end
  end
end
