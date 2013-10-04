class SSOPushCredential

  PERMISSIONS = [
    "signin",
    "user_update_permission"
  ]

  cattr_accessor :user_email, :user

  class UserNotFound < StandardError; end
  class UserNotProvided < StandardError; end

  def self.credentials(application)
    user.grant_permissions(application, PERMISSIONS)

    user.authorisations.
          create_with(expires_in: 10.years).
          find_or_create_by_application_id(application.id).token
  end

  def self.user
    raise UserNotProvided unless user_email.present?
    @@user ||= User.find_by_email(user_email) || raise(UserNotFound)
  end

end
