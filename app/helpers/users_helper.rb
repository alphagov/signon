module UsersHelper
  def organisation_options(form_builder)
    accessible_organisations = Organisation.accessible_by(current_ability)
    options_from_collection_for_select(accessible_organisations, :id,
      :name_with_abbreviation, selected: form_builder.object.organisation_id)
  end

  def organisation_select_options
    { include_blank: current_user.role == 'organisation_admin' ? false : 'None' }
  end

  def user_email_tokens(user = current_user)
    [ user.email ] + DeviseZxcvbn::EmailTokeniser.split(user.email)
  end

  def minimum_password_length
    User.password_length.min
  end

  def current_path_with_role_filter(role_name)
    query_parameters = (request.query_parameters || {})
    role_name.nil? ? query_parameters.delete(:role) : query_parameters.merge!(role: role_name)
    request.path_info + '?' + query_parameters.map { |k,v| "#{k}=#{v}" }.join('&')
  end

  def user_role_text
    "#{params[:role] if params[:role]} user accounts".strip.humanize.capitalize
  end

  def user_role_list_items
    list_items = User.roles.map do |role_name|
      content_tag(:li,
        link_to(role_name.humanize, current_path_with_role_filter(role_name)),
        class: params[:role] == role_name ? 'active' : '')
    end
    list_items << content_tag(:li, link_to("All roles", current_path_with_role_filter(nil)))
    raw list_items.join("\n")
  end

  def edit_user_path_by_user_type(user)
    user.api_user? ? edit_superadmin_api_user_path(user) : edit_admin_user_path(user)
  end
end
