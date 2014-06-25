require 'push_user_updates_worker'
require 'sso_push_client'

class ReauthEnforcer
  include PushUserUpdatesWorker

  def perform(uid, application_id)
    application = ::Doorkeeper::Application.find_by_id(application_id)
    # It's possible the application has been deleted between when the job was scheduled and run.
    return if application.nil?

    api = SSOPushClient.new(application)
    api.reauth_user(uid)
  end

end
