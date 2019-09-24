require "sso_push_client"

class ReauthEnforcer < PushUserUpdatesJob
  def perform(uid, application_id)
    application = ::Doorkeeper::Application.find_by_id(application_id)
    # It's possible the application has been deleted between when the job was scheduled and run.
    return if application.nil?

    api = SSOPushClient.new(application)
    api.reauth_user(uid)
  end
end
