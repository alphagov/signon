class UsersFilter
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
    filtered_users = filtered_users.with_role(options[:roles]) if options[:roles]
    filtered_users.includes(:organisation).order(:name)
  end

  def paginated_users
    users.page(options[:page]).per(options[:per_page])
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
end
