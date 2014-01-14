class InactiveUsersSuspensionReminder
  def send_reminders
    mailing_list = users_by_days_to_suspension
    mailing_list.each do |days, users|
      users.each do |user|
        tries = 3
        begin
          Rails.logger.info "#{self.class}: Sending email to #{user.email}."
          UserMailer.suspension_reminder(user, days).deliver
          Rails.logger.info "#{self.class}: Successfully sent email to #{user.email}."
        rescue *network_errors => e
          Rails.logger.debug "#{self.class}: #{e.class} - #{e.message} while sending email to #{user.email} during attempt (#{(tries..3).count}/3)."
          retry if (tries -= 1) > 0

          Rails.logger.warn "#{self.class}: Failed to send suspension reminder email to #{user.email}."
          ExceptionNotifier::Notifier.background_exception_notification e, data: { receiver_email: user.email }
        rescue AWS::SES::ResponseError => e
          Rails.logger.warn "#{self.class}: #{e.response.error.message} while sending email to #{user.email}."
          ExceptionNotifier::Notifier.background_exception_notification e, data: { receiver_email: user.email }
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
