class OrganisationUsersSuspender
  attr_reader :organisation, :reason_for_suspension

  def initialize(organisation:, reason_for_suspension:)
    @organisation = organisation
    @reason_for_suspension = reason_for_suspension
  end

  def suspend
    User.with_organisation(organisation).not_suspended.each do |user|
      user.suspend(reason_for_suspension)

      PermissionUpdater.perform_on(user)
      ReauthEnforcer.perform_on(user)

      EventLog.record_event(user, EventLog::ACCOUNT_BULK_SUSPENDED)
      UserMailer.suspension_notification(user).deliver_now
    end
  end

  def unsuspend
    User.with_organisation(organisation).suspended.with_suspension_reason(reason_for_suspension).each do |user|
      user.unsuspend

      EventLog.record_event(user, EventLog::ACCOUNT_BULK_UNSUSPENDED)
      UserMailer.suspension_notification(user).deliver_now
    end
  end
end
