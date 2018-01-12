class InactiveUsersSuspensionReminder
  ERRORS_TO_RETRY_ON = [Timeout::Error,
                        SocketError,
                        Net::SMTPServerBusy,
                        Errno::ETIMEDOUT,
                        Errno::EHOSTUNREACH,
                        Errno::ECONNREFUSED,
                        EOFError]

  def initialize(users, days_to_suspension)
    @users = users
    @days_to_suspension = days_to_suspension
  end

  def send_reminders
    @users.each do |user|
      tries = 3
      begin
        Rails.logger.info "#{self.class}: Sending email to #{user.email}."
        UserMailer.suspension_reminder(user, @days_to_suspension).deliver_now
        Rails.logger.info "#{self.class}: Successfully sent email to #{user.email}."
      rescue *ERRORS_TO_RETRY_ON => e
        Rails.logger.debug "#{self.class}: #{e.class} - #{e.message} while sending email to #{user.email} during attempt (#{(tries..3).count}/3)."
        sleep(3) && retry if (tries -= 1) > 0

        Rails.logger.warn "#{self.class}: Failed to send suspension reminder email to #{user.email}."
        log_error(e, user)
      rescue => e
        log_error(e, user)
        begin
          Rails.logger.warn "#{self.class}: #{e.response.error.message} while sending email to #{user.email}."
        rescue NoMethodError
          Rails.logger.warn "#{self.class}: #{e.message} while sending email to #{user.email}."
        end
      end
    end
  end

private

  def log_error(e, user)
    GovukError.notify e, extra: { receiver_email: user.email }
  end
end
