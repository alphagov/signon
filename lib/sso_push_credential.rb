class SSOPushCredential
  PERMISSIONS = %w[signin user_update_permission].freeze
  USER_NAME = "Signonotron API Client (permission and suspension updater)".freeze
  USER_EMAIL = "signon+permissions@alphagov.co.uk".freeze

  class << self
    def credentials(application)
      user.grant_application_permissions(application, PERMISSIONS)

      user.authorisations
        .create_with(expires_in: 10.years)
        .find_or_create_by!(application_id: application.id).token
    end

    def user
      User.find_by(email: USER_EMAIL) || create_user!
    end

  private

    def create_user!
      ApiUser.build(name: USER_NAME, email: USER_EMAIL).tap(&:save!)
    end
  end
end
