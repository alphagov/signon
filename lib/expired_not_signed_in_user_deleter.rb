class ExpiredNotSignedInUserDeleter
  def delete
    User.expired_never_signed_in.find_each do |user|
      EventLog.record_event(
        user,
        EventLog::ACCOUNT_DELETED,
        trailing_message: log_message(user),
      )

      user.destroy!
    end
  end

private

  def log_message(user)
    "#{user.email} was invited on " \
      "#{user.invitation_sent_at.to_fs(:short_ordinal)} and never signed in"
  end
end
