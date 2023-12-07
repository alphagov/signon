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

    record_update
    record_permission_changes(old_permissions)
    record_role_change
    record_organisation_change
    record_2sv_exemption_removed
    record_2sv_mandated
    send_two_step_mandated_notification
    perform_permissions_update
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
        initiator: current_user,
        application_id:,
        trailing_message: "(#{permissions.map(&:name).join(', ')})",
        ip_address: true,
      )
    end

    permissions_removed.each do |application_id, permissions|
      EventLog.record_event(
        user,
        EventLog::PERMISSIONS_REMOVED,
        initiator: current_user,
        application_id:,
        trailing_message: "(#{permissions.map(&:name).join(', ')})",
        ip_address: true,
      )
    end
  end

  def record_update
    EventLog.record_event(
      user,
      EventLog::ACCOUNT_UPDATED,
      initiator: current_user,
      ip_address: true,
    )
  end

  def record_role_change
    role_change = user.previous_changes[:role]
    return unless role_change

    EventLog.record_role_change(
      user,
      role_change.first,
      role_change.last,
    )
  end

  def record_organisation_change
    organisation_change = user.previous_changes[:organisation_id]
    return unless organisation_change

    EventLog.record_organisation_change(
      user,
      Organisation.find_by(id: organisation_change.first)&.name || Organisation::NONE,
      Organisation.find_by(id: organisation_change.last)&.name || Organisation::NONE,
    )
  end

  def record_2sv_exemption_removed
    return unless user.require_2sv && user.previous_changes[:reason_for_2sv_exemption]

    EventLog.record_event(
      user,
      EventLog::TWO_STEP_EXEMPTION_REMOVED,
      initiator: current_user,
      ip_address: true,
    )
  end

  def record_2sv_mandated
    return unless user.require_2sv && user.previous_changes[:require_2sv]

    EventLog.record_event(
      user,
      EventLog::TWO_STEP_MANDATED,
      initiator: current_user,
      ip_address: true,
    )
  end

  def perform_permissions_update
    PermissionUpdater.perform_on(user)
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
