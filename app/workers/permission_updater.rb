require 'push_user_updates_worker'
require 'sso_push_client'

class PermissionUpdater
  include PushUserUpdatesWorker

  def perform(uid, application_id)
    user, application = User.find_by_uid(uid), ::Doorkeeper::Application.find_by_id(application_id)
    # It's possible they've been deleted between when the job was scheduled and run.
    return if user.nil? or application.nil?

    api, presenter = SSOPushClient.new(application), UserOAuthPresenter.new(user, application)
    api.update_user(user.uid, presenter.as_hash)

    user.permissions_synced!(application)
  end

end
