module UserFilterHelper

  def current_path_with_filter(filter_type, filter_value)
    query_parameters = (request.query_parameters.clone || {})
    filter_value.nil? ? query_parameters.delete(filter_type) : query_parameters.merge!(filter_type => filter_value)
    request.path_info + '?' + query_parameters.map { |k,v| "#{k}=#{v}" }.join('&')
  end

  def user_role_text
    "#{params[:role] if params[:role]} users".strip.humanize.capitalize
  end

  def user_filter_list_items(filter_type)
    case filter_type
    when :role
      items = filtered_user_roles
    when :status
      items = User::USER_STATUSES
    end

    list_items = items.map do |item_name|
      content_tag(:li,
      link_to(item_name.humanize, current_path_with_filter(filter_type, item_name)),
      class: params[filter_type] == item_name ? 'active' : '')
    end

    list_items << content_tag(:li,
      link_to("All #{filter_type.to_s.pluralize}",
      current_path_with_filter(filter_type, nil)))

    list_items.join("\n").html_safe
  end

  def filtered_user_roles
    current_user.manageable_roles
  end

  def any_filter?
    params[:filter].present? || params[:role].present? || params[:status].present?
  end
end
