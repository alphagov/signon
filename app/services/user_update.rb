class UserUpdate
  attr_reader :user, :user_params

  def initialize(user, user_params)
    @user = user
    @user_params = user_params
  end

  def call
    user.skip_reconfirmation!
    old_permissions = fetch_user_permissions
    return unless update_user

    user.application_permissions.reload

    record_permission_changes(old_permissions)
    send_two_step_mandated_notification
    record_email_change_and_notify
    true
  end

private

  def filtered_user_params
    return user_params unless user_params.key?(:supported_permission_ids)

    filter = SupportedPermissionParameterFilter.new(current_user, user, user_params)
    user_params.merge(supported_permission_ids: filter.filtered_supported_permission_ids)
  end

  def update_user
    user.update(filtered_user_params)
  end

  def record_permission_changes(old_permissions)
    new_permissions = fetch_user_permissions

    permissions_added = (new_permissions - old_permissions).group_by(&:application_id)
    permissions_removed = (old_permissions - new_permissions).group_by(&:application_id)

    permissions_added.each do |application_id, permissions|
      EventLog.record_event(
        user,
        EventLog::PERMISSIONS_ADDED,
        initiator: true,
        application_id:,
        trailing_message: "(#{permissions.map(&:name).join(', ')})",
        ip_address: true,
      )
    end

    permissions_removed.each do |application_id, permissions|
      EventLog.record_event(
        user,
        EventLog::PERMISSIONS_REMOVED,
        initiator: true,
        application_id:,
        trailing_message: "(#{permissions.map(&:name).join(', ')})",
        ip_address: true,
      )
    end
  end

  def send_two_step_mandated_notification
    if user.send_two_step_mandated_notification?
      UserMailer.two_step_mandated(user).deliver_later
    end
  end

  def record_email_change_and_notify
    email_change = user.previous_changes[:email]
    return unless email_change

    EventLog.record_email_change(user, email_change.first, email_change.last)

    return if user.api_user?

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

  def current_user = Current.user
end
