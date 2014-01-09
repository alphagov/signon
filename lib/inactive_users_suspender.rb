class InactiveUsersSuspender

  def initialize(suspension_threshold = SUSPENSION_THRESHOLD_PERIOD)
    @suspension_threshold = suspension_threshold
  end

  def suspend
    inactive_users.update_all(suspended_at: Time.zone.now, reason_for_suspension: reason)
  end

private

  def inactive_users
    User.last_signed_in_before(@suspension_threshold.days.ago)
  end

  def reason
    "User has not logged in for #{@suspension_threshold} days since " +
      "#{@suspension_threshold.next.days.ago.strftime('%d/%m/%Y')}"
  end
end
