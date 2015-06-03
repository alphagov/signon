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
    when :organisation
      items = Organisation.order(:name).joins(:users).uniq.map {|org| [org.id, org.name_with_abbreviation]}
    end

    list_items = items.map do |item|
      if item.is_a? String
        item_id = item
        item_name = item.humanize
      else
        item_id = item[0].to_s
        item_name = item[1]
      end
      content_tag(:li,
      link_to(item_name, current_path_with_filter(filter_type, item_id)),
      class: params[filter_type] == item_id ? 'active' : '')
    end

    list_items << content_tag(:li,
      link_to("All #{filter_type.to_s.pluralize}",
      current_path_with_filter(filter_type, nil)))

    list_items.join("\n").html_safe
  end

  def filtered_user_roles
    current_user.manageable_roles
  end

  def filter_value(filter_type)
    value = params[filter_type]
    return nil if value.blank?
    if filter_type == :organisation
      org = Organisation.find(value)
      if org.abbreviation.presence
        content_tag(:abbr, org.abbreviation, title: org.name)
      else
        org.name
      end
    else
      value.humanize.capitalize
    end
  end

  def any_filter?
    params[:filter].present? || params[:role].present? || params[:status].present? || params[:organisation].present?
  end
end
