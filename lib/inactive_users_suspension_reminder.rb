class InactiveUsersSuspensionReminder

  def initialize(users, days_to_suspension)
    @users, @days_to_suspension = users, days_to_suspension
  end

  def send_reminders
    @users.each do |user|
      tries = 3
      begin
        Rails.logger.info "#{self.class}: Sending email to #{user.email}."
        UserMailer.suspension_reminder(user, @days_to_suspension).deliver
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

private

  def network_errors
    [SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTDOWN, Errno::EHOSTUNREACH, Errno::ETIMEDOUT]
  end

end
