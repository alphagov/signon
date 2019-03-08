class SSOPushCredential
  PERMISSIONS = %w(signin user_update_permission).freeze

  class UserNotFound < StandardError; end
  class UserNotProvided < StandardError; end

  class << self
    attr_accessor :user_email
    attr_writer :user

    def credentials(application)
      user.grant_application_permissions(application, PERMISSIONS)

      user.authorisations.
        create_with(expires_in: 10.years).
        find_or_create_by(application_id: application.id).token
    end

    def user
      raise UserNotProvided unless user_email.present?

      @user ||= User.find_by_email(user_email) || raise(UserNotFound)
    end
  end
end
