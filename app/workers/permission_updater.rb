require 'push_user_updates_worker'
require 'sso_push_client'

class PermissionUpdater
  include PushUserUpdatesWorker

  def perform(uid, application_id)
    user, application = User.find_by_uid(uid), ::Doorkeeper::Application.find(application_id)
    api, presenter = SSOPushClient.new(application), UserOAuthPresenter.new(user, application)

    api.update_user(uid, presenter.as_hash)
    user.permissions.detect { |perm| perm.application_id == application.id }.synced!
  end

end
