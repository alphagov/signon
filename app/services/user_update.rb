class UserUpdate
  attr_reader :user, :user_params, :current_user, :user_ip

  def initialize(user, user_params, current_user, user_ip)
    @user = user
    @user_params = user_params
    @current_user = current_user
    @user_ip = user_ip
  end

  def update
    user.skip_reconfirmation!
    old_permissions = fetch_user_permissions
    return unless update_user

    user.application_permissions.reload

    record_update
    record_permission_changes(old_permissions)
    record_role_change
    send_two_step_flag_notification
    perform_permissions_update
    record_email_change_and_notify
    true
  end

private

  def filtered_user_params
    filter = SupportedPermissionParameterFilter.new(current_user, user, user_params)
    user_params.merge(supported_permission_ids: filter.filtered_supported_permission_ids)
  end

  def update_user
    user.update_attributes(filtered_user_params)
  end

  def record_permission_changes(old_permissions)
    new_permissions = fetch_user_permissions

    permissions_added = (new_permissions - old_permissions).group_by(&:application_id)
    permissions_removed = (old_permissions - new_permissions).group_by(&:application_id)

    permissions_added.each do |application_id, permissions|
      EventLog.record_event(
        user,
        EventLog::PERMISSIONS_ADDED,
        initiator: current_user,
        application_id: application_id,
        trailing_message: "(#{permissions.map(&:name).join(', ')})",
        ip_address: user_ip,
      )
    end

    permissions_removed.each do |application_id, permissions|
      EventLog.record_event(
        user,
        EventLog::PERMISSIONS_REMOVED,
        initiator: current_user,
        application_id: application_id,
        trailing_message: "(#{permissions.map(&:name).join(', ')})",
        ip_address: user_ip,
      )
    end
  end

  def record_update
    EventLog.record_event(
      user,
      EventLog::ACCOUNT_UPDATED,
      initiator: current_user,
      ip_address: user_ip,
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

  Permission = Struct.new(:name, :application_id)

  def fetch_user_permissions
    user.application_permissions.includes(:supported_permission).map do |p|
      Permission.new(p.supported_permission.name, p.application_id)
    end
  end
end
