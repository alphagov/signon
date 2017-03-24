class UserUpdatedEvent
  attr_reader :affected_user, :current_user
  def initialize(affected_user, current_user)
    @affected_user = affected_user
    @current_user = current_user
  end

  def record
    record_update
    record_role_change
  end

private

  def record_update
    EventLog.record_event(
      affected_user,
      EventLog::ACCOUNT_UPDATED,
      initiator: current_user
    )
  end

  def record_role_change
    role_change = affected_user.previous_changes[:role]
    return unless role_change

    EventLog.record_role_change(
      affected_user,
      role_change.first,
      role_change.last,
      current_user
    )
  end
end
