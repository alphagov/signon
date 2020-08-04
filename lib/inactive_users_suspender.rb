class InactiveUsersSuspender
  def suspend
    inactive_users = User.not_recently_unsuspended.last_signed_in_before(User::SUSPENSION_THRESHOLD_PERIOD.ago).each do |user|
      user.suspended_at = Time.zone.now
      user.reason_for_suspension = reason
      user.save!(validate: false)

      PermissionUpdater.perform_on(user)
      ReauthEnforcer.perform_on(user)

      EventLog.record_event(user, EventLog::ACCOUNT_AUTOSUSPENDED)
      UserMailer.suspension_notification(user).deliver_now
    end

    inactive_users.count
  end

private

  def reason
    "User has not logged in for #{User::SUSPENSION_THRESHOLD_PERIOD.inspect} since" \
      " #{(User::SUSPENSION_THRESHOLD_PERIOD + 1.day).ago.strftime('%d %B %Y')}"
  end
end
