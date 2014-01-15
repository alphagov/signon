class InactiveUsersSuspender

  def suspend
    inactive_users.update_all(suspended_at: Time.zone.now, reason_for_suspension: reason)
  end

private

  def inactive_users
    User.last_signed_in_before(User::SUSPENSION_THRESHOLD_PERIOD.ago)
  end

  def reason
    "User has not logged in for #{User::SUSPENSION_THRESHOLD_PERIOD.inspect} since" +
      " #{(User::SUSPENSION_THRESHOLD_PERIOD + 1.day).ago.strftime('%d %B %Y')}"
  end
end
