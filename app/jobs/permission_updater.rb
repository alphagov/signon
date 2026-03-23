require "sso_push_client"

class PermissionUpdater < PushUserUpdatesJob
  def perform(uid, application_id)
    user = User.find_by(uid:)
    application = Doorkeeper::Application.find_by(id: application_id)
    # It's possible they've been deleted between when the job was scheduled and run.
    return if user.nil? || application.nil?
    return unless application.supports_push_updates?

    api = SSOPushClient.new(application)
    presenter = UserOAuthPresenter.new(user, application)
    api.update_user(user.uid, presenter.as_hash)

    unless user.permissions_for(application).include?(SupportedPermission::SIGNIN_NAME)
      ReauthEnforcer.perform_later(uid, application_id)
    end

    user.permissions_synced!(application)
  end
end
