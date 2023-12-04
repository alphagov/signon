module UsersHelper
  include Pundit::Authorization

  def status(user)
    user.status.humanize
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

  def organisation_options(form_builder)
    accessible_organisations = policy_scope(Organisation)
    options_from_collection_for_select(
      accessible_organisations,
      :id,
      :name_with_abbreviation,
      selected: form_builder.object.organisation_id,
    )
  end

  def organisation_select_options
    { include_blank: current_user.publishing_manager? ? false : Organisation::NONE }
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

  def assignable_user_roles
    current_user.manageable_roles
  end

  def user_name(user)
    anchor_tag = link_to(user.name, edit_user_path(user), class: "govuk-link")
    user.suspended? ? content_tag(:del, anchor_tag) : anchor_tag
  end

  def options_for_role_select(selected: nil)
    assignable_user_roles.map do |role|
      { text: role.humanize, value: role }.tap do |option|
        option[:selected] = true if option[:value] == selected
      end
    end
  end

  def options_for_organisation_select(selected: nil)
    [{ text: "None", value: nil }] + policy_scope(Organisation).not_closed.order(:name).map do |organisation|
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

  def link_to_access_log(user)
    link_to "Account access log", event_logs_user_path(user)
  end

  def link_to_suspension(user)
    return unless policy(user).suspension?

    link_to user.suspended? ? "Unsuspend user" : "Suspend user", edit_suspension_path(user)
  end

  def link_to_resend_invitation(user)
    return unless policy(user).resend_invitation?
    return unless user.invited_but_not_yet_accepted?

    link_to "Resend signup email", edit_user_invitation_resend_path(user)
  end
end
