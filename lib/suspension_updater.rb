class SuspensionUpdater
  def initialize(user, applications)
    @user, @applications = user, applications
  end

  def attempt
    Propagator.new(
      @user,
      @applications,
      self.class.updater,
      Proc.new {}
    ).attempt
  end

  def self.updater
    Proc.new do |user, application|
      api = SSOPushClient.new(application)
      api.reauth_user(user.uid)
    end
  end
end
