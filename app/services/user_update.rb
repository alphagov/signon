class UserUpdate
  attr_reader :user, :user_params, :current_user

  def initialize(user, user_params, current_user)
    @user = user
    @user_params = user_params
    @current_user = current_user
  end

  def update
    user.skip_reconfirmation!
    return unless user.update_attributes(user_params)

    record_update
    record_role_change
    send_two_step_flag_notification
    perform_permissions_update
    record_email_change_and_notify
    true
  end

private

  def record_update
    EventLog.record_event(
      user,
      EventLog::ACCOUNT_UPDATED,
      initiator: current_user,
    )
  end

  def record_role_change
    role_change = user.previous_changes[:role]
    return unless role_change

    EventLog.record_role_change(
      user,
      role_change.first,
      role_change.last,
      current_user,
    )
  end

  def perform_permissions_update
    user.application_permissions.reload
    PermissionUpdater.perform_on(user)
  end

  def send_two_step_flag_notification
    if user.send_two_step_flag_notification?
      UserMailer.two_step_flagged(user).deliver_later
    end
  end

  def record_email_change_and_notify
    email_change = user.previous_changes[:email]
    return unless email_change
    EventLog.record_email_change(user, email_change.first, email_change.last, current_user)

    user.invite! if user.invited_but_not_yet_accepted?

    email_change.each do |to_address|
      UserMailer.email_changed_by_admin_notification(user, email_change.first, to_address).deliver_later
    end
  end
end
