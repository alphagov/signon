module UsersHelper
  include Pundit::Authorization

  def status(user)
    user.status.humanize
  end

  def status_with_tag(user)
    css_classes = if user.status == User::USER_STATUS_ACTIVE
                    "govuk-tag--green"
                  else
                    "govuk-tag--grey"
                  end

    govuk_tag(status(user), css_classes)
  end

  def two_step_status(user)
    user.two_step_status.humanize.capitalize
  end

  def two_step_status_with_requirement(user)
    if user.not_setup_2sv? && user.require_2sv?
      "Required but #{two_step_status(user).downcase}"
    else
      two_step_status(user)
    end
  end

  def user_email_tokens(user = current_user)
    [user.email] + DeviseZxcvbn::EmailTokeniser.split(user.email)
  end

  def minimum_password_length
    User.password_length.min
  end

  def edit_user_path_by_user_type(user)
    user.api_user? ? edit_api_user_path(user) : edit_user_path(user)
  end

  def sync_needed?(permissions)
    max_updated_at = permissions.map(&:updated_at).compact.max
    max_last_synced_at = permissions.map(&:last_synced_at).compact.max
    max_updated_at.present? && max_last_synced_at.present? ? max_updated_at > max_last_synced_at : false
  end

  def formatted_number_of_users(users)
    pluralize(number_with_delimiter(users.total_count), "user")
  end

  def filtered_users_heading(users)
    count = formatted_number_of_users(users)
    if current_user.manageable_organisations.one?
      "#{count} in #{current_user.manageable_organisations.first.name}"
    else
      count
    end
  end

  def user_name(user)
    link_to(user.name, edit_user_path(user), class: "govuk-link")
  end

  def options_for_role_select(selected: nil)
    current_user.manageable_roles.map do |role|
      { text: role.display_name, value: role.name }.tap do |option|
        option[:selected] = true if option[:value] == selected
      end
    end
  end

  def options_for_organisation_select(selected: nil)
    [{ text: "None", value: nil }] + policy_scope(Organisation).not_closed.map do |organisation|
      { text: organisation.name_with_abbreviation, value: organisation.id }.tap do |option|
        option[:selected] = true if option[:value] == selected
      end
    end
  end

  def options_for_permission_option_select(application:, user: nil)
    application.sorted_supported_permissions_grantable_from_ui.map do |permission|
      {
        label: formatted_permission_name(application.name, permission.name),
        value: permission.id,
        checked: user&.has_permission?(permission),
      }
    end
  end

  def formatted_permission_name(application_name, permission_name)
    if permission_name == SupportedPermission::SIGNIN_NAME
      "Has access to #{application_name}?"
    else
      permission_name
    end
  end

  def user_role_select_hint
    render "govuk_publishing_components/components/list", {
      visible_counters: true,
      items: [
        "<strong>Superadmins</strong> can create and edit all user types and edit applications.",
        "<strong>Admins</strong> can create and edit normal users.",
        "<strong>Super Organisation Admins</strong> can unlock and unsuspend their organisation and related organisation accounts.",
        "<strong>Organisation Admins</strong> can unlock and unsuspend their organisation accounts.",
      ],
    }
  end

  def summary_list_item_for_name(user)
    href = user.api_user? ? edit_api_user_name_path(user) : edit_user_name_path(user)
    { field: "Name", value: user.name, edit: { href: } }
  end

  def summary_list_item_for_email(user)
    href = user.api_user? ? edit_api_user_email_path(user) : edit_user_email_path(user)
    { field: "Email", value: user.email, edit: { href: } }
  end

  def summary_list_item_for_organisation(user)
    item = { field: "Organisation", value: user.organisation_name }
    item[:edit] = { href: edit_user_organisation_path(user) } if policy(user).assign_organisation?
    item
  end

  def summary_list_item_for_role(user)
    item = { field: "Role", value: user.role_display_name }
    item[:edit] = { href: edit_user_role_path(user) } if policy(user).assign_role?
    item
  end

  def summary_list_item_for_status(user)
    { field: "Status", value: status(user) }
  end

  def summary_list_item_for_2sv_status(user)
    { field: "2-step verification", value: two_step_status_with_requirement(user) }
  end

  def link_to_access_log(user)
    link_to "View account access log", event_logs_user_path(user), class: "govuk-link"
  end

  def link_to_suspension(user)
    return unless policy(user).suspension?

    link_to user.suspended? ? "Unsuspend user" : "Suspend user", edit_suspension_path(user), class: "govuk-link"
  end

  def link_to_resend_invitation(user)
    return unless policy(user).resend_invitation?
    return unless user.invited_but_not_yet_accepted?

    link_to "Resend invitation email", edit_user_invitation_resend_path(user), class: "govuk-link"
  end

  def link_to_unlock(user)
    return unless policy(user).unlock?
    return unless user.access_locked?

    link_to "Unlock account", edit_user_unlocking_path(user), class: "govuk-link"
  end

  def link_to_2sv_exemption(user)
    return unless policy(user).exempt_from_two_step_verification?

    text = user.exempt_from_2sv? ? "Edit 2-step verification exemption" : "Exempt user from 2-step verification"
    link_to text, edit_two_step_verification_exemption_path(user), class: "govuk-link"
  end

  def link_to_reset_2sv(user)
    return unless policy(user).reset_2sv?
    return unless user.has_2sv?

    link_to "Reset 2-step verification", edit_user_two_step_verification_reset_path(user), class: "govuk-link"
  end

  def link_to_mandate_2sv(user)
    return unless policy(user).mandate_2sv?
    return if user.require_2sv?

    text = "Turn on 2-step verification for this user"
    text += " (this will remove their exemption)" if user.exempt_from_2sv?
    link_to text, edit_user_two_step_verification_mandation_path(user), class: "govuk-link"
  end
end
