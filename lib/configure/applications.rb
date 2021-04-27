module Configure
  class Applications
    def initialize(public_domain:, resource_name_prefix:)
      @public_domain = public_domain
      @name_prefix = resource_name_prefix
    end

    def configure!(applications = [])
      applications.each do |application|
        home_uri = "https://#{application.fetch('subdomain_name')}.#{public_domain}"
        redirect_url = URI.join(home_uri, application.fetch("redirect_path")).to_s
        find_or_create_application(
          name: [name_prefix, application.fetch("name")].join,
          redirect_uri: redirect_url,
          description: application.fetch("description"),
          home_uri: home_uri,
          supported_permissions: application.fetch("permissions"),
        )
      end
    end

  private

    attr_reader :public_domain, :name_prefix

    def find_or_create_application(name:, redirect_uri:, description:, home_uri:, supported_permissions:)
      application = Doorkeeper::Application.find_or_create_by!(name: name) do |app|
        app.redirect_uri = redirect_uri
        app.description = description
        app.home_uri = home_uri
      end
      supported_permissions.each do |permission|
        SupportedPermission.find_or_create_by!(application_id: application.id, name: permission)
      end
    end
  end
end
