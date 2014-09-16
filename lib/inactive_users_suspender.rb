class InactiveUsersSuspender

  def suspend
    count = 0
    inactive_users = User.last_signed_in_before(User::SUSPENSION_THRESHOLD_PERIOD.ago).each do |user|
      next if user.recently_unsuspended?

      user.suspended_at = Time.zone.now
      user.reason_for_suspension = reason
      user.save(validate: false)

      EventLog.record_event(user, EventLog::ACCOUNT_AUTOSUSPENDED)
      UserMailer.suspension_notification(user).deliver
      count += 1
    end

    count
  end

private

  def reason
    "User has not logged in for #{User::SUSPENSION_THRESHOLD_PERIOD.inspect} since" +
      " #{(User::SUSPENSION_THRESHOLD_PERIOD + 1.day).ago.strftime('%d %B %Y')}"
  end
end
