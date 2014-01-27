class ReauthEnforcer
  include Sidekiq::Worker

  def self.perform_on(user)
    user.applications_used.each { |application| self.perform_async(user.uid, application.id) }
  end

  def perform(uid, application_id)
    api = SSOPushClient.new(::Doorkeeper::Application.find(application_id))
    api.reauth_user(uid)
  end

end
