class UsersFilter
  CHECKBOX_FILTER_KEYS = %i[statuses two_step_statuses roles permissions organisations].freeze
  PERMITTED_CHECKBOX_FILTER_PARAMS = CHECKBOX_FILTER_KEYS.each.with_object({}) { |k, h| h[k] = [] }.freeze

  attr_reader :options

  def initialize(users, current_user, options = {})
    @users = users
    @current_user = current_user
    @options = options
    @options[:per_page] ||= 25
  end

  def users
    filtered_users = @users
    filtered_users = filtered_users.with_partially_matching_name_or_email(options[:filter].strip) if options[:filter]
    filtered_users = filtered_users.with_statuses(options[:statuses]) if options[:statuses]
    filtered_users = filtered_users.with_2sv_statuses(options[:two_step_statuses]) if options[:two_step_statuses]
    filtered_users = filtered_users.with_role(options[:roles]) if options[:roles]
    filtered_users = filtered_users.with_permission(options[:permissions]) if options[:permissions]
    filtered_users = filtered_users.with_organisation(options[:organisations]) if options[:organisations]
    filtered_users.includes(:organisation).order(:name)
  end

  def paginated_users
    users.page(options[:page]).per(options[:per_page])
  end

  def status_option_select_options
    User::USER_STATUSES.map do |status|
      {
        label: status.humanize.capitalize,
        value: status,
        checked: Array(options[:statuses]).include?(status),
      }
    end
  end

  def two_step_status_option_select_options
    User::TWO_STEP_STATUSES_VS_NAMED_SCOPES.map do |status, scope_name|
      {
        label: status.humanize.capitalize,
        value: scope_name,
        checked: Array(options[:two_step_statuses]).include?(scope_name),
      }
    end
  end

  def role_option_select_options
    @current_user.manageable_roles.map do |role|
      {
        label: role.humanize.capitalize,
        value: role,
        checked: Array(options[:roles]).include?(role),
      }
    end
  end

  def permission_option_select_options
    Doorkeeper::Application.includes(:supported_permissions).flat_map do |application|
      application.supported_permissions.map do |permission|
        {
          label: "#{application.name} #{permission.name}",
          value: permission.to_param,
          checked: Array(options[:permissions]).include?(permission.to_param),
        }
      end
    end
  end

  def organisation_option_select_options
    scope = @current_user.manageable_organisations
    scope.order(:name).joins(:users).uniq.map do |organisation|
      {
        label: organisation.name_with_abbreviation,
        value: organisation.to_param,
        checked: Array(options[:organisations]).include?(organisation.to_param),
      }
    end
  end

  def no_options_selected_for?(key)
    Array(options[key]).none?
  end

  def any_options_selected?
    options.slice(*CHECKBOX_FILTER_KEYS).values.any?
  end
end
