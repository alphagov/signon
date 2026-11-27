class OrganisationUsersSuspender
  attr_reader :organisation, :reason_for_suspension

  def initialize(organisation, reason_for_suspension)
    @organisation = organisation
    @reason_for_suspension = reason_for_suspension
  end

  def suspend
    organisation_users = User.with_organisation(organisation).not_suspended.each do |user|
      user.suspended_at = Time.current
      user.reason_for_suspension = reason_for_suspension
      user.save!(validate: false)

      user.revoke_all_authorisations

      PermissionUpdater.perform_on(user)
      ReauthEnforcer.perform_on(user)

      EventLog.record_event(user, EventLog::ACCOUNT_SUSPENDED)
      UserMailer.suspension_notification(user).deliver_now
    end

    organisation_users.count
  end

  def unsuspend
    organisation_users = User.with_organisation(organisation).with_suspension_reason(reason_for_suspension).each do |user|
      EventLog.record_event(user, EventLog::ACCOUNT_UNSUSPENDED)
      UserMailer.suspension_notification(user).deliver_now
    end

    organisation_users.count
  end
end
