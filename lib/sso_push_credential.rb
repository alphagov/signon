class SSOPushCredential
  PERMISSIONS = %w[user_update_permission].freeze

  class << self
    def credentials(application)
      return if application.retired?

      user.grant_application_signin_permission(application)
      user.grant_application_permissions(application, PERMISSIONS)

      user.authorisations
        .not_expired
        .expires_after(4.weeks.from_now)
        .create_with(expires_in: 10.years)
        .find_or_create_by!(application_id: application.id).token
    end

    def user
      ApiUser.for_sso_push
    end
  end
end
