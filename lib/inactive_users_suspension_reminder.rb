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
          Airbrake.notify_or_ignore e, :parameters => { :receiver_email => user.email }
        rescue AWS::SES::ResponseError => e
          Rails.logger.warn "#{self.class}: #{e.response.error.message} while sending email to #{user.email}."
          Airbrake.notify_or_ignore e, :parameters => { :receiver_email => user.email }
        end
      end
    end
    mailing_list.values.flatten.uniq.count
  end

  def users_by_days_to_suspension
    suspension_threshold_exceeded = User::SUSPENSION_THRESHOLD_PERIOD + 1.day

    users_by_days_to_suspension = [14, 7, 3, 1].inject({}) do |result, days_to_suspension|
      result[days_to_suspension] = User.last_signed_in_on((suspension_threshold_exceeded - days_to_suspension.days).ago)
      result
    end
    users_by_days_to_suspension[1] += User.last_signed_in_before(suspension_threshold_exceeded.ago).to_a
    users_by_days_to_suspension
  end

private

  def network_errors
    [SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTDOWN, Errno::EHOSTUNREACH, Errno::ETIMEDOUT]
  end

end
