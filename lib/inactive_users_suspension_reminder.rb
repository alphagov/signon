class InactiveUsersSuspensionReminder
  def send_reminders
    mailing_list = users_by_days_to_suspension
    mailing_list.each do |days, users|
      users.each do |user|
        tries = 3
        begin
          UserMailer.suspension_reminder(user, days).deliver
        rescue *network_errors => e
          retry if (tries -= 1) > 0
        end
      end
    end
    mailing_list.values.flatten.uniq.count
  end

  def users_by_days_to_suspension
    users_by_days_to_suspension = [14, 7, 3, 1].inject({}) do |result, days|
      result[days] = User.last_signed_in_on((SUSPENSION_THRESHOLD_PERIOD.next - days).days.ago)
      result
    end
    users_by_days_to_suspension[1] += User.last_signed_in_before(SUSPENSION_THRESHOLD_PERIOD.next.days.ago).to_a
    users_by_days_to_suspension
  end

private

  def network_errors
    [SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTDOWN, Errno::EHOSTUNREACH, Errno::ETIMEDOUT]
  end

end
