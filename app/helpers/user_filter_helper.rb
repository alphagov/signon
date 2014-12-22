module UserFilterHelper

  def current_path_with_role_filter(role_name)
    query_parameters = (request.query_parameters.clone || {})
    role_name.nil? ? query_parameters.delete(:role) : query_parameters.merge!(role: role_name)
    request.path_info + '?' + query_parameters.map { |k,v| "#{k}=#{v}" }.join('&')
  end

  def current_path_with_status_filter(status_name)
    query_parameters = (request.query_parameters.clone || {})
    status_name.nil? ? query_parameters.delete(:status) : query_parameters.merge!(status: status_name)
    request.path_info + '?' + query_parameters.map { |k,v| "#{k}=#{v}" }.join('&')
  end

  def user_role_text
    "#{params[:role] if params[:role]} users".strip.humanize.capitalize
  end

  def user_role_list_items
    list_items = filtered_user_roles.map do |role_name|
      content_tag(:li,
      link_to(role_name.humanize, current_path_with_role_filter(role_name)),
      class: params[:role] == role_name ? 'active' : '')
    end
    list_items << content_tag(:li, link_to("All roles", current_path_with_role_filter(nil)))
    raw list_items.join("\n")
  end

  def user_status_list_items
    list_items = User::USER_STATUSES.map do |status_name|
      content_tag(:li,
      link_to(status_name.humanize, current_path_with_status_filter(status_name)),
      class: params[:status] == status_name ? 'active' : '')
    end
    list_items << content_tag(:li, link_to("All statuses", current_path_with_status_filter(nil)))
    raw list_items.join("\n")
  end

  def filtered_user_roles
    current_user.manageable_roles
  end
end
