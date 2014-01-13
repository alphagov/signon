class PermissionUpdater
  def initialize(user, applications)
    @user, @applications = user, applications
  end

  def attempt
    ::Propagator.new(
      @user,
      @applications,
      self.class.updater,
      self.class.on_success
    ).attempt
  end

  def self.updater
    Proc.new do |user, application|
      api = SSOPushClient.new(application)
      presenter = UserOAuthPresenter.new(user, application)
      api.update_user(user.uid, presenter.as_hash)
    end
  end

  def self.on_success
    Proc.new do |user, application|
      user.permissions.detect { |perm| perm.application_id == application.id }.synced!
    end
  end
end
