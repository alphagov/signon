require 'push_user_updates_worker'
require 'sso_push_client'

class ReauthEnforcer
  include PushUserUpdatesWorker

  def perform(uid, application_id)
    api = SSOPushClient.new(::Doorkeeper::Application.find(application_id))
    api.reauth_user(uid)
  end

end
